const { after, before, beforeEach, test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  Timestamp,
  collection,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  setLogLevel,
  updateDoc,
  where,
} = require('firebase/firestore');

setLogLevel('silent');

let environment;
const approved = { role: 'worker', status: 'approved', category: 'plumber' };
const projectId = 'demo-mazdoorlink-visits';

before(async () => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error('Run these tests with a local Firestore emulator.');
  }
  environment = await initializeTestEnvironment({
    projectId,
    firestore: { rules: readFileSync(join(__dirname, '../../firestore.rules'), 'utf8') },
  });
});

beforeEach(async () => {
  await environment.clearFirestore();
  await environment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const profiles = {
      customer: { name: 'Customer', role: 'customer' },
      stranger: { name: 'Other customer', role: 'customer' },
      admin: { name: 'Admin', role: 'admin' },
      worker: { ...approved, name: 'Worker', isOnline: false },
      otherWorker: { name: 'Other worker', role: 'customer', roles: ['customer', 'worker'], workerStatus: 'approved', category: 'electrician' },
      pending: { name: 'Pending', role: 'worker', status: 'pending' },
      paused: { ...approved, name: 'Paused', acceptsVisits: false },
      suspended: { ...approved, name: 'Suspended', status: 'suspended', workerStatus: 'approved' },
    };
    await Promise.all(Object.entries(profiles).map(([id, profile]) => setDoc(doc(db, 'users', id), profile)));
    await setDoc(doc(db, 'jobs', 'existing-job'), {
      customerId: 'customer', workerId: 'worker', price: 850, status: 'accepted',
    });
  });
});

after(async () => environment?.cleanup());

const db = (uid) => uid == null
  ? environment.unauthenticatedContext().firestore()
  : environment.authenticatedContext(uid).firestore();
const visitRef = (uid, id = 'first') => doc(db(uid), 'visit_requests', id);
const payload = (overrides = {}) => ({
  customerId: 'customer',
  customerName: 'Customer',
  workerId: 'worker',
  workerName: 'Worker',
  address: '23 Example Street, Islamabad',
  preferredAt: Timestamp.fromMillis(Date.now() + 60 * 60 * 1000),
  note: 'The sink is leaking.',
  status: 'requested',
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  ...overrides,
});
const change = (uid, status, overrides = {}, id = 'first') =>
  updateDoc(visitRef(uid, id), { status, updatedAt: serverTimestamp(), ...overrides });

async function myVisits(uid, field) {
  return getDocs(query(collection(db(uid), 'visit_requests'), where(field, '==', uid), orderBy('createdAt', 'desc')));
}

test('a customer can book an offline worker and only those participants can see it', async () => {
  await assertSucceeds(setDoc(visitRef('customer'), payload()));
  assert.equal((await assertSucceeds(getDoc(visitRef('worker')))).data().workerId, 'worker');
  assert.equal((await assertSucceeds(myVisits('customer', 'customerId'))).size, 1);
  assert.equal((await assertSucceeds(myVisits('worker', 'workerId'))).size, 1);
  assert.equal((await assertSucceeds(myVisits('otherWorker', 'workerId'))).size, 0);
  await assertFails(getDoc(visitRef('otherWorker')));
  await assertFails(getDoc(visitRef('admin')));
  await assertFails(getDoc(visitRef(null)));
  await assertFails(getDocs(collection(db('customer'), 'visit_requests')));
});

test('cannot request yourself, an unapproved, paused or suspended worker, or impersonate a customer', async () => {
  for (const [workerId, workerName] of [['customer', 'Customer'], ['pending', 'Pending'], ['paused', 'Paused'], ['suspended', 'Suspended']]) {
    await assertFails(setDoc(visitRef('customer'), payload({ workerId, workerName })));
  }
  await assertFails(setDoc(visitRef('stranger'), payload()));
  await assertFails(setDoc(visitRef(null), payload()));
  await assertSucceeds(setDoc(visitRef('customer'), payload({ workerId: 'otherWorker', workerName: 'Other worker' })));
});

test('requests require a future time and an address and cannot contain financial fields', async () => {
  for (const fields of [
    { price: 100 }, { status: 'accepted' }, { address: '  ' }, { note: 'x'.repeat(501) },
    { customerName: 'Spoofed name' }, { preferredAt: Timestamp.fromMillis(1) },
  ]) {
    await assertFails(setDoc(visitRef('customer'), payload(fields)));
  }
  await assertSucceeds(setDoc(visitRef('customer'), payload({ note: '' })));
});

test('only the assigned worker can accept and complete; details cannot be changed', async () => {
  await assertSucceeds(setDoc(visitRef('customer'), payload()));
  await assertFails(change('otherWorker', 'accepted'));
  await assertFails(change('customer', 'accepted'));
  await assertFails(change('worker', 'completed'));
  await assertFails(change('worker', 'accepted', { address: 'Changed' }));
  await assertSucceeds(change('worker', 'accepted'));
  await assertFails(change('customer', 'completed'));
  await assertSucceeds(change('worker', 'completed'));
  await assertFails(change('worker', 'accepted'));
  await assertFails(change('customer', 'cancelled'));
  assert.equal((await assertSucceeds(getDoc(doc(db('customer'), 'jobs', 'existing-job')))).data().status, 'accepted');
});

test('declines and cancellations are terminal; pausing requests does not cancel an existing visit', async () => {
  await assertSucceeds(setDoc(visitRef('customer'), payload()));
  await assertSucceeds(setDoc(visitRef('customer', 'second'), payload()));
  await assertSucceeds(updateDoc(doc(db('worker'), 'users', 'worker'), { acceptsVisits: false }));
  await assertFails(setDoc(visitRef('customer', 'third'), payload()));
  await assertSucceeds(change('worker', 'declined'));
  await assertFails(change('worker', 'accepted'));
  await assertSucceeds(change('worker', 'accepted', {}, 'second'));
  await assertSucceeds(change('customer', 'cancelled', {}, 'second'));
  await assertFails(change('worker', 'completed', {}, 'second'));
});

test('a visit cannot be accepted after its preferred time has passed', async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'visit_requests', 'first'),
      payload({ preferredAt: Timestamp.fromMillis(1) }));
  });
  await assertFails(change('worker', 'accepted'));
  await assertSucceeds(change('worker', 'declined'));
});

test('users may apply for worker approval, but cannot grant themselves approval or admin role', async () => {
  const ref = doc(db('customer'), 'users', 'customer');
  await assertFails(updateDoc(ref, { role: 'admin' }));
  await assertFails(updateDoc(ref, { role: 'worker', status: 'approved' }));
  await assertFails(setDoc(doc(db('new-account'), 'users', 'new-account'), { role: 'worker', workerStatus: 'approved' }));
  await assertSucceeds(updateDoc(ref, { role: 'worker', roles: ['customer', 'worker'], status: 'pending', workerStatus: 'pending' }));
  await assertSucceeds(updateDoc(doc(db('admin'), 'users', 'customer'), { status: 'approved', workerStatus: 'approved' }));
  await assertSucceeds(updateDoc(ref, { name: 'Updated name' }));
  await assertFails(updateDoc(doc(db('suspended'), 'users', 'suspended'), { status: 'pending' }));
});

test('existing repair jobs still update, but clients cannot create new ones', async () => {
  const customer = db('customer');
  await assertFails(setDoc(doc(customer, 'jobs', 'new-job'), { customerId: 'customer', workerId: 'worker', status: 'pending' }));
  await assertSucceeds(updateDoc(doc(customer, 'jobs', 'existing-job'), { status: 'cancelled' }));
});
