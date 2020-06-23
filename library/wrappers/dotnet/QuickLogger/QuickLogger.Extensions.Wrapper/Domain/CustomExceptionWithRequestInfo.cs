using System;

namespace QuickLogger.Extensions.Wrapper.Domain
{
    public class CustomExceptionWithHTTPRequestInfo
    {
        private object _additionalinfo;
        private string _custommessage;
        private Exception _exception;
        public string CustomMessage { get { return _custommessage; } }
        public Exception Exception { get { return _exception; } }
        public object AdditionalInfo { get { return _additionalinfo; } }
        public CustomExceptionWithHTTPRequestInfo(Exception exception, string CustomMessage, object AdditionalInfo = null)
        {
            _custommessage = CustomMessage;
            _additionalinfo = AdditionalInfo;
            _exception = exception;
        }
    }
}
