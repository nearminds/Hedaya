package hedaya.shared

import kotlinx.serialization.Serializable

@Serializable
enum class ConsistencyLevel(val arabicName: String) {
    veryRegular("منتظم جدًا"),
    sometimes("أحيانًا"),
    startStop("أبدأ وأتوقف"),
    freshStart("بداية جديدة");
}

@Serializable
enum class TimeAvailability(val arabicName: String) {
    veryLittle("قليل جدًا"),
    medium("متوسط"),
    more("كثير"),
    varies("يختلف");
}

@Serializable
enum class PrimaryIntention(val arabicName: String) {
    discipline("انضباط"),
    closeness("قرب من الله"),
    learning("تعلّم"),
    habit("بناء عادة");
}

@Serializable
enum class WorshipArea(val arabicName: String) {
    salah("الصلاة"),
    quran("القرآن"),
    dhikr("الذكر"),
    dua("الدعاء"),
    sadaqah("الصدقة"),
    zakat("الزكاة"),
    goodDeeds("أعمال الخير");
}

@Serializable
enum class Pace(val arabicName: String) {
    gentle("لطيف"),
    balanced("متوازن"),
    ambitious("طموح");
}

@Serializable
enum class TrackingFeeling(val arabicName: String) {
    motivating("محفّز"),
    sometimesHeavy("ثقيل أحيانًا"),
    preferMinimal("أفضّل الحدّ الأدنى");
}

@Serializable
enum class LifeContext(val arabicName: String) {
    busyParent("والد/ة مشغول/ة"),
    student("طالب/ة"),
    traveler("مسافر/ة"),
    none("لا ينطبق");
}

@Serializable
data class WorshipProfile(
    val consistency: ConsistencyLevel = ConsistencyLevel.freshStart,
    val timeAvailability: TimeAvailability = TimeAvailability.medium,
    val primaryIntention: PrimaryIntention = PrimaryIntention.closeness,
    val worshipAreas: Set<WorshipArea> = emptySet(),
    val pace: Pace = Pace.balanced,
    val trackingFeeling: TrackingFeeling = TrackingFeeling.motivating,
    val lifeContext: LifeContext = LifeContext.none
) {
    val mercyDaysPerWeek: Int
        get() = when (pace) {
            Pace.gentle -> 2
            Pace.balanced -> 2
            Pace.ambitious -> 1
        }
}

@Serializable
data class PlanEssentialItem(
    val id: String,
    val title: String,
    val icon: String
)

@Serializable
data class PlanBonusItem(
    val id: String,
    val title: String,
    val icon: String
)
