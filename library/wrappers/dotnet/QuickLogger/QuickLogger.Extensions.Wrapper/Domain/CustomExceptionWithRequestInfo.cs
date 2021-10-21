using System;

namespace QuickLogger.Extensions.Wrapper.Domain
{
    public class CustomExceptionWithHTTPRequestInfo
    {
        private object _scopeInfo;
        private string _custommessage;
        private Exception _exception;
        private string _className;

        public string ClassName { get { return _className; } }
        public string CustomMessage { get { return _custommessage; } }
        public Exception Exception { get { return _exception; } }
        public object ScopeInfo { get { return _scopeInfo; } }
        public CustomExceptionWithHTTPRequestInfo(string className, Exception exception, string customMessage, object scopeInfo = null)
        {
            _className = className;
            _custommessage = customMessage;
            _scopeInfo = scopeInfo;
            _exception = exception;
        }
    }
}
