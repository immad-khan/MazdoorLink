import sys, re

def fix():
    f = open('lib/screens/mazdoor_flow.dart', 'r', encoding='utf-8')
    content = f.read()
    f.close()

    content = content.replace('_isForgotPassword ?? false', '_isForgotPassword')
    content = content.replace('_obscurePassword ?? true', '_obscurePassword')
    content = content.replace('_obscureConfirmPassword ?? true', '_obscureConfirmPassword')
    content = content.replace('showUrdu ?? false', 'showUrdu')
    content = content.replace("job.descriptionEn ?? 'Service'", "job.descriptionEn")
    content = content.replace("job.descriptionUr ?? 'سروس'", "job.descriptionUr")
    content = content.replace('job?.descriptionEn ?? "Service"', 'job.descriptionEn')
    content = content.replace('job?.descriptionUr ?? "سروس"', 'job.descriptionUr')

    f = open('lib/screens/mazdoor_flow.dart', 'w', encoding='utf-8')
    f.write(content)
    f.close()

fix()
