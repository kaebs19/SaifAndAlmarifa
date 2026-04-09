//
//  AppStrings.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Core/AppStrings.swift
//  المسؤول عن إدارة النصوص الثابتة في التطبيق
//  ✅ مكان واحد لكل النصوص - سهولة الترجمة والتعديل

import Foundation

// MARK: - App Strings
enum AppStrings {

    // MARK: - Common
    enum Common {
        static let appName = "سيف المعرفة"
        static let ok = "حسناً"
        static let cancel = "إلغاء"
        static let save = "حفظ"
        static let delete = "حذف"
        static let edit = "تعديل"
        static let done = "تم"
        static let loading = "جاري التحميل..."
        static let retry = "إعادة المحاولة"
        static let error = "حدث خطأ"
        static let success = "تم بنجاح"
    }

    // MARK: - Authentication
    enum Auth {
        static let login = "تسجيل الدخول"
        static let register = "إنشاء حساب"
        static let createAccount = "إنشاء حساب جديد"
        static let logout = "تسجيل الخروج"
        static let email = "البريد الإلكتروني"
        static let password = "كلمة المرور"
        static let confirmPassword = "تأكيد كلمة المرور"
        static let forgotPassword = "نسيت كلمة المرور؟"
        static let orContinueWith = "أو تابع باستخدام"
        static let continueWithApple = "Apple"
        static let continueWithGoogle = "Google"
        static let dontHaveAccount = "ليس لديك حساب؟"
        static let alreadyHaveAccount = "لديك حساب بالفعل؟"

        // Welcome Screen
        static let appTitle = "سيف المعرفة"
        static let appTagline = "تحدى أصدقاءك. اهدم قلاعهم. كن الأذكى."
        static let startJourney = "ابدأ رحلتك"
        static let startJourneySubtitle = "سجّل دخولك للانضمام إلى المعركة"

        // Login Screen
        static let welcomeBack = "أهلاً بعودتك"
        static let loginSubtitle = "سجّل دخولك لمتابعة معاركك"
        static let emailLabel = "البريد الإلكتروني"
        static let passwordLabel = "كلمة المرور"

        // Register Screen
        static let joinBattle = "انضم إلى المعركة"
        static let createAccountSubtitle = "أنشئ حسابك وابدأ رحلتك"
        static let usernamePlaceholder = "اختر اسماً مميزاً"
        static let emailPlaceholder = "example@email.com"
        static let passwordHint = "8 أحرف على الأقل"
        static let confirmPasswordPlaceholder = "أعد كتابة كلمة المرور"
        static let createAccountButton = "إنشاء الحساب"
        static let or = "أو"

        // Terms
        static let agreeTo = "أوافق على"
        static let termsOfService = "شروط الاستخدام"
        static let and = "و"
        static let privacyPolicy = "سياسة الخصوصية"

        // Forgot Password - Step 1 (Email)
        static let forgotTitle = "استعادة كلمة المرور"
        static let forgotSubtitle = "أدخل بريدك لإرسال رمز التحقق"
        static let sendCode = "إرسال الرمز"

        // Forgot Password - Step 2 (Code)
        static let verifyCodeTitle = "تحقق من البريد"
        static let verifyCodeSubtitlePrefix = "أدخل الرمز المُرسَل إلى"
        static let codePlaceholder = "••••••"
        static let verifyCodeButton = "تأكيد الرمز"
        static let didNotReceiveCode = "لم تستلم الرمز؟"
        static let resendCode = "أعد الإرسال"

        // Forgot Password - Step 3 (New Password)
        static let newPasswordTitle = "كلمة مرور جديدة"
        static let newPasswordSubtitle = "اختر كلمة مرور قوية"
        static let newPasswordPlaceholder = "كلمة المرور الجديدة"
        static let savePassword = "حفظ كلمة المرور"
        static let passwordResetSuccess = "تم تغيير كلمة المرور بنجاح"
    }

    // MARK: - Validation Errors
    enum Errors {
        static let usernameRequired = "اسم المستخدم مطلوب"
        static let usernameTooShort = "اسم المستخدم قصير جداً"
        static let emailRequired = "البريد الإلكتروني مطلوب"
        static let emailInvalid = "البريد الإلكتروني غير صحيح"
        static let passwordRequired = "كلمة المرور مطلوبة"
        static let passwordTooShort = "كلمة المرور يجب أن تكون 8 أحرف على الأقل"
        static let passwordsDoNotMatch = "كلمات المرور غير متطابقة"
        static let mustAgreeTerms = "يجب الموافقة على الشروط"
        static let codeRequired = "الرمز مطلوب"
        static let codeInvalid = "الرمز غير صحيح"
    }

    // MARK: - Game Features
    enum Features {
        static let liveBattles = "معارك مباشرة"
        static let buildCastle = "ابنِ قلعتك"
        static let variousQuestions = "أسئلة متنوعة"
    }

    // MARK: - Settings
    enum Settings {
        static let title = "الإعدادات"
        static let account = "الحساب"
        static let preferences = "التفضيلات"
        static let notifications = "الإشعارات"
        static let privacy = "الخصوصية والأمان"
        static let appearance = "المظهر"
        static let language = "اللغة"
        static let about = "حول التطبيق"
    }
}
