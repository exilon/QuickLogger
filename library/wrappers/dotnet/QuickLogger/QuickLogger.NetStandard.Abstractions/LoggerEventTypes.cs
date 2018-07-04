using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using System.Text;

namespace QuickLogger.NetStandard.Abstractions
{    
    public static class LoggerEventTypes
    {
        public enum EventType { etHeader, etInfo, etSuccess, etWarning, etError, etCritical, etException, etDebug, etTrace, etDone, etCustom1, etCustom2 }        
        public static HashSet<EventType> LOG_ONLYERRORS = new HashSet<EventType>() {EventType.etHeader, EventType.etInfo, EventType.etError, EventType.etCritical, EventType.etException };
        public static HashSet<EventType> LOG_ERRORSANDWARNINGS = new HashSet<EventType>() { EventType.etInfo, EventType.etSuccess, EventType.etWarning, EventType.etError, EventType.etCritical, EventType.etException };
        public static HashSet<EventType> LOG_BASIC = new HashSet<EventType>() { EventType.etHeader, EventType.etInfo, EventType.etSuccess, EventType.etDone, EventType.etWarning, EventType.etError, EventType.etCritical, EventType.etException, EventType.etCustom1, EventType.etCustom2 };
        public static HashSet<EventType> LOG_ALL = new HashSet<EventType>() { EventType.etHeader, EventType.etInfo, EventType.etSuccess, EventType.etWarning, EventType.etError, EventType.etCritical, EventType.etException, EventType.etDebug, EventType.etTrace, EventType.etDone, EventType.etCustom1, EventType.etCustom2 };
        public static HashSet<EventType> LOG_TRACE = new HashSet<EventType>() { EventType.etHeader, EventType.etInfo, EventType.etSuccess, EventType.etDone, EventType.etWarning, EventType.etError, EventType.etCritical, EventType.etException, EventType.etTrace };
        public static HashSet<EventType> LOG_DEBUG = new HashSet<EventType>() { EventType.etHeader, EventType.etInfo, EventType.etSuccess, EventType.etDone, EventType.etWarning, EventType.etError, EventType.etCritical, EventType.etException, EventType.etTrace, EventType.etDebug };
        public static HashSet<EventType> LOG_VERBOSE = LOG_ALL;
    };
}
