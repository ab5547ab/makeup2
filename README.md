# סטודיו לאיפור - יומן עבודה וניהול תורים 💄📅

אפליקציית Flutter מלאה ומשוכללת לניהול יומן עבודה ותורים לאיפור/עיצוב שיער -
כוללת לוח שנה **עברי** חזותי, ניהול תורים מלא (הוספה/עריכה/מחיקה), סטטיסטיקות
הכנסה חודשית, וגיבוי/שחזור אוטומטי ל-GitHub.

## מה השתנה מהגרסה הקודמת?

בבדיקת הפרויקט המקורי נמצאה הסיבה המרכזית לכשלון ביצירת ה-APK: הפרויקט הכיל
רק את קוד ה-Dart (`lib/`) וקובץ Kotlin בודד, בלי שום שלד אנדרואיד. מסך לוח
השנה גם היה placeholder ריק ללא פונקציונליות.

### הגרסה הזו כוללת:

| תחום | מה נוסף/שופר |
|---|---|
| **שלד אנדרואיד** | ⭐ **נוצר אוטומטית בכל בנייה** במקום תחזוקה ידנית - ראו הסבר בהמשך |
| **לוח שנה עברי** | לוח שנה מלא לפי **חודשים עבריים** (למשל "אלול תשפ״ו") עם ניווט בין חודשים, גימטריה לימים, ונקודות סימון לימים עם תורים |
| **ניהול תורים** | מסך הוספה/עריכה מלא: שם, טלפון, תאריך ושעה, משך זמן, קטגוריה, מחיר, הערות, סטטוס |
| **שמירת נתונים** | כל התורים נשמרים במכשיר עצמו (`shared_preferences`) - עובד גם לגמרי אופליין |
| **סטטיסטיקות** | סרגל עליון עם מספר תורים והכנסה חודשית מחושבים אוטומטית |
| **סנכרון GitHub** | גיבוי **וגם** שחזור, עם מיזוג חכם של נתונים, ושמירת ההגדרות מקומית |
| **בנייה אוטומטית** | workflow ל-GitHub Actions שבונה APK אוטומטית בכל פוש |

## ⭐ למה שלד האנדרואיד "נוצר אוטומטית" ולא נשמר בריפו?

זהו שינוי חשוב לעומת גרסה קודמת של הפרויקט הזה. קבצי ה-Gradle/AGP/Kotlin
הנדרשים לבניית אפליקציית Flutter **מתעדכנים לעיתים קרובות מאוד**, וגרסת
Flutter המותקנת אצל GitHub Actions מתעדכנת אוטומטית ברקע (כי אנחנו משתמשים
ב-`channel: stable`). המשמעות: אם שומרים בריפו קבצי גרסה מוצמדים ידנית
(למשל "Gradle 8.14"), הם עלולים תוך שבועות להפוך ללא תואמים לגרסת Flutter
העדכנית - וזו בדיוק השגיאה שקיבלתם כמה פעמים ברצף.

**הפתרון:** ה-workflow (`.github/workflows/build-apk.yml`) מריץ בכל בנייה את
הפקודה `flutter create --platforms=android .`, שמייצרת מחדש את כל שלד
האנדרואיד (Gradle, AGP, Kotlin, כל הקבצים) **בהתאמה מדויקת** לגרסת ה-Flutter
שמותקנת באותו הרגע - בלי צורך לנחש או לתחזק גרסאות ידנית, לעולם.

מיד אחרי זה, שלב נוסף ("Apply custom native files") "מטליא" מעל השלד הטרי
את שלושת הקבצים המותאמים אישית לאפליקציה שלכם - שנמצאים בתיקיית
`native_overrides/` ואינם תלויי-גרסה:
- **אייקון האפליקציה** (בצבעי הסטודיו)
- **`MainActivity.kt`** - עם ערוץ ה-Wi-Fi המותאם
- **`AndroidManifest.xml`** - עם הרשאות האינטרנט/Wi-Fi/חיוג הנדרשות

כך מקבלים גם עדכניות מלאה וגם את ההתאמות האישיות - בלי לוותר על אף אחד מהם.

## מבנה הפרויקט

```
makeup_calendar/
├── lib/                                  # כל קוד ה-Dart (ראו טבלה למטה)
├── native_overrides/                     # קבצים מותאמים אישית שמוטמעים בכל build
│   ├── MainActivity.kt
│   ├── AndroidManifest.xml
│   └── res/mipmap-*/ic_launcher.png
├── .github/workflows/build-apk.yml       # בנייה אוטומטית + הטמעת native_overrides
└── pubspec.yaml
```

| קובץ Dart | תפקיד |
|---|---|
| `lib/main.dart` | נקודת כניסה + הגדרת Provider |
| `lib/models/appointment.dart` | מודל תור + קטגוריות + סטטוסים |
| `lib/services/appointments_controller.dart` | ניהול מצב התורים (ChangeNotifier) |
| `lib/services/storage_service.dart` | שמירה מקומית (shared_preferences) |
| `lib/services/github_sync_service.dart` | גיבוי/שחזור מול GitHub |
| `lib/services/wifi_service.dart` | חיבור ל-Wi-Fi של הסטודיו |
| `lib/utils/hebrew_date_helper.dart` | המרות תאריך עברי⇄לועזי (מבוסס kosher_dart) |
| `lib/widgets/hebrew_month_grid.dart` | רכיב לוח השנה העברי |
| `lib/screens/calendar_screen.dart` | מסך ראשי: לוח שנה עברי + רשימת תורים ליום |
| `lib/screens/add_edit_appointment_screen.dart` | טופס הוספה/עריכה |
| `lib/screens/settings_screen.dart` | הגדרות סנכרון ו-Wi-Fi |
| `lib/theme/app_theme.dart` | ערכת הנושא של האפליקציה |

## איך בונים APK - שתי דרכים

### 🌟 דרך א' (מומלצת): בנייה אוטומטית ב-GitHub, בלי להתקין כלום

1. העלו את כל תוכן התיקייה הזו לריפו ב-GitHub (**לא** צריך תיקיית `android/`
   בכלל - אם קיימת אצלכם, אפשר להשמיט אותה, ה-workflow יוצר אותה מחדש).
2. עברו לטאב **Actions** → תראו ריצה אוטומטית של "Build APK".
3. בסיום הריצה (כ-3-5 דקות), גללו ל-**Artifacts** → הורידו את
   `makeup-calendar-apk`.
4. העבירו את קובץ ה-APK לטלפון והתקינו (אשרו "התקנה ממקורות לא ידועים").

### דרך ב': בנייה מקומית

```
flutter pub get
flutter create --platforms=android --org com.mua .
cp native_overrides/MainActivity.kt android/app/src/main/kotlin/com/mua/makeup_calendar/MainActivity.kt
cp native_overrides/AndroidManifest.xml android/app/src/main/AndroidManifest.xml
cp native_overrides/res/mipmap-*/ic_launcher.png android/app/src/main/res/mipmap-*/  # (עתיקו לכל תיקיית mipmap בנפרד)
flutter build apk --release
```

קובץ ה-APK הסופי יימצא ב-`build/app/outputs/flutter-apk/app-release.apk`.

## הערות אבטחה חשובות

- **טוקן GitHub**: השתמשו בריפו **פרטי** ובטוקן עם הרשאת `repo` בלבד.
- **סיסמת Wi-Fi**: נשמרת רק בזיכרון הזמני של המסך.
- **אייקון האפליקציה**: ניתן להחליף ב-`native_overrides/res/mipmap-*/ic_launcher.png`.

## פיתוח עתידי מוצע

- תזכורות Push לפני תורים (`flutter_local_notifications`)
- ניהול לקוחות נפרד עם היסטוריית תורים
- ייצוא דוח הכנסות חודשי ל-PDF
- גיבוי אוטומטי מתוזמן
