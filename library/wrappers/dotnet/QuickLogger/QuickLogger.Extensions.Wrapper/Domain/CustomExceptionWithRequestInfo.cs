using System;

namespace QuickLogger.Extensions.Wrapper.Domain
{
    public class CustomExceptionWithHTTPRequestInfo
    {
        private object _additionalinfo;
        private string _custommessage;
        private Exception _exception;
        private string _className;

        public string ClassName { get { return _className; } }
        public string CustomMessage { get { return _custommessage; } }
        public Exception Exception { get { return _exception; } }
        public object AdditionalInfo { get { return _additionalinfo; } }
        public CustomExceptionWithHTTPRequestInfo(string className, Exception exception, string CustomMessage, object AdditionalInfo = null)
        {
            _className = className;
            _custommessage = CustomMessage;
            _additionalinfo = AdditionalInfo;
            _exception = exception;
        }
    }
}
