# Import all models so Alembic can detect them via Base.metadata
from app.models.base import Base  # noqa: F401
from app.models.user import User, OAuthAccount, TokenBlacklist  # noqa: F401
from app.models.teacher import (  # noqa: F401
    Teacher,
    TeacherEducation,
    TeacherCareer,
    TeacherCertificate,
)
from app.models.student import Student  # noqa: F401
from app.models.lesson import (  # noqa: F401
    LessonClass,
    ClassMembership,
    LessonLocation,
    Lesson,
    LessonPiece,
    LessonRecording,
)
from app.models.subscription import (  # noqa: F401
    Subscription,
    SubscriptionUsage,
    SubscriptionTemplate,
    SubscriptionProposal,
)
from app.models.payment import Payment, TuitionSettings  # noqa: F401
from app.models.practice import (  # noqa: F401
    PracticeRepertoire,
    PracticeSection,
    DailyPracticeStatus,
    PracticeRecording,
    PracticeNote,
    PracticeGoal,
    PracticeStreak,
    PracticeItem,
)
from app.models.relationship import TeacherStudentRelation, Follow  # noqa: F401
from app.models.schedule import (  # noqa: F401
    TeacherAvailability,
    AvailabilityTimeSlot,
    LessonBooking,
    LessonRequest,
    GroupClass,
)
from app.models.notification import Notification  # noqa: F401
from app.models.device_token import DeviceToken  # noqa: F401
from app.models.parent import Parent, ParentChildRelation, ParentTeacherConnection  # noqa: F401
from app.models.policy import LessonPolicy, MakeupLesson, ScheduleConfirmationCard  # noqa: F401
from app.models.i18n import I18nTranslation, SupportedLocale  # noqa: F401
from app.models.tip import TipTemplate  # noqa: F401
from app.models.invite import Invite, ConnectionRequest, Connection  # noqa: F401
from app.models.gamification import GamificationPoint, GamificationBadge  # noqa: F401
from app.models.settings import (  # noqa: F401
    TeacherSettings,
    SubscriptionSettings,
    ProposalSettings,
    NotificationSettings,
    ParentNotificationSettings,
    FeedbackPreset,
    TeachingResource,
)
from app.models.review import TeacherReview  # noqa: F401
from app.models.schedule_ext import (  # noqa: F401
    ScheduleException,
    GroupClassSchedule,
    GroupClassBooking,
    NoShowRecord,
    LessonScheduleChange,
)
from app.models.practice_log import PracticeLog  # noqa: F401
