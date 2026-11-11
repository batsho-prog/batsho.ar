# باتشو (Batsho)

تطبيق تعارف وزواج للعرب والمسلمين، مبني بـ **Flutter** و **Supabase**.

## الميزات الحالية (MVP)
- تسجيل الدخول وإنشاء حساب بالبريد وكلمة المرور
- إنشاء الملف الشخصي (صورة، عمر، دولة، حالة اجتماعية، الهدف، نبذة)
- استكشاف الملفات مع تصفية (العمر، الدولة، الهدف)
- الإعجاب والمطابقة المتبادلة
- دردشة لحظية بين المتطابقين فقط
- الحظر والإبلاغ
- شارة التوثيق (يتم تفعيلها من لوحة Supabase فقط، ولا يستطيع المستخدم تعديلها)

## التشغيل
1. ثبّت [Flutter](https://docs.flutter.dev/get-started/install).
2. أنشئ مشروعًا في [Supabase](https://supabase.com) ونفّذ `supabase/schema.sql` من SQL Editor.
3. من Storage أنشئ bucket عامًا اسمه `avatars`، وأضف سياسة تسمح للمستخدم المسجّل برفع ملفاته داخل مجلد باسم معرّفه.
4. ضع `supabaseUrl` و`supabaseAnonKey` في `lib/core/config.dart`.
5. أنشئ ملفات المنصات ثم شغّل التطبيق:

```bash
flutter create . --org com.batsho --project-name batsho
flutter pub get
flutter run
```

> الأمر `flutter create .` يضيف مجلدي android وios دون الكتابة فوق ملفات `lib` الموجودة.
> تأكد أن `uses-permission` لقراءة الصور مفعّلة على أندرويد وNSPhotoLibraryUsageDescription على iOS.

## أفكار للمرحلة التالية
- توثيق الحسابات بصورة سيلفي أو رقم هاتف
- إشعارات الرسائل (FCM)
- الاشتراك المدفوع عبر RevenueCat
- مراجعة الصور قبل ظهورها
- سياسة الخصوصية وشروط الاستخدام (مطلوبة للنشر على Google Play)
