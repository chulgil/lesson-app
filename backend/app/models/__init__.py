# Import all models so Alembic can detect them via Base.metadata
from app.models.app_billing import AppBillingPlan, IapReceipt  # noqa: F401
from app.models.app_version import AppNews, AppRoadmap, AppVersion  # noqa: F401
from app.models.base import Base  # noqa: F401
from app.models.device_token import DeviceToken  # noqa: F401
from app.models.gamification import GamificationBadge, GamificationPoint  # noqa: F401
from app.models.i18n import I18nTranslation, SupportedLocale  # noqa: F401
from app.models.invite import Connection, ConnectionRequest, Invite  # noqa: F401
from app.models.lesson import (  # noqa: F401
    ClassMembership,
    Lesson,
    LessonClass,
    LessonLocation,
    LessonPiece,
    LessonRecording,
)
from app.models.manual_teacher import ManualTeacher  # noqa: F401
from app.models.notification import Notification, UserNotificationPreference  # noqa: F401
from app.models.onboarding import UserOnboardingProgress, UserOnboardingQuestProgress  # noqa: F401
from app.models.parent import (  # noqa: F401
    Parent,
    ParentChildRelation,
    ParentInvitation,
    ParentTeacherConnection,
    ParentVisibilitySettings,
)
from app.models.payment import Payment, TuitionSettings  # noqa: F401
from app.models.policy import LessonPolicy, MakeupLesson, ScheduleConfirmationCard  # noqa: F401
from app.models.post import TeacherPost  # noqa: F401
from app.models.practice import (  # noqa: F401
    DailyPracticeStatus,
    PracticeGoal,
    PracticeItem,
    PracticeItemResource,
    PracticeNote,
    PracticePiece,
    PracticeRecording,
    PracticeRepertoire,
    PracticeSection,
    PracticeStreak,
    RecordingFeedback,
    StudentPracticePiece,
)
from app.models.practice_log import PracticeLog  # noqa: F401
from app.models.relationship import Follow, TeacherStudentRelation  # noqa: F401
from app.models.request_event import (  # noqa: F401
    RequestEvent,
    RequestEventType,
    ScheduleChangeType,
)
from app.models.review import TeacherReview  # noqa: F401
from app.models.schedule import (  # noqa: F401
    AvailabilityTimeSlot,
    GroupClass,
    LessonBooking,
    LessonRequest,
    TeacherAvailability,
    VacationPeriod,
)
from app.models.schedule_ext import (  # noqa: F401
    GroupClassBooking,
    GroupClassSchedule,
    LessonScheduleChange,
    NoShowRecord,
    ScheduleException,
)
from app.models.settings import (  # noqa: F401
    FeedbackCategory,
    FeedbackPreset,
    FeedbackTemplate,
    FeedbackTemplateTag,
    NotificationSettings,
    ParentNotificationSettings,
    ProposalSettings,
    SubscriptionSettings,
    TeacherSettings,
    TeachingResource,
    TeachingResourceTag,
)
from app.models.share_token import ShareToken  # noqa: F401
from app.models.student import Student  # noqa: F401
from app.models.subscription import (  # noqa: F401
    Subscription,
    SubscriptionProposal,
    SubscriptionTemplate,
    SubscriptionUsage,
)
from app.models.subscription_expiry import SubscriptionExpiryDispatchLog  # noqa: F401
from app.models.teacher import (  # noqa: F401
    Teacher,
    TeacherCareer,
    TeacherCertificate,
    TeacherEducation,
)
from app.models.teacher_announcement import (  # noqa: F401
    TeacherAnnouncement,
    TeacherAnnouncementDate,
)
from app.models.tip import TipTemplate  # noqa: F401
from app.models.user import OAuthAccount, TokenBlacklist, User  # noqa: F401
