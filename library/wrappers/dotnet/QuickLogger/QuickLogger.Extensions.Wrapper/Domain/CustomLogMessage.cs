using System;
using System.Collections.Generic;
using System.Text;

namespace QuickLogger.Extensions.Wrapper.Domain
{
    public class CustomLogMessage
    {
        private object _scopeInfo;
        private string _custommessage;
        private string _classname;

        public string ClassName { get { return _classname; } }
        public string CustomMessage { get { return _custommessage; } }
        public object ScopeInfo { get { return _scopeInfo; } }

        public CustomLogMessage(string classname, string msg, object scopeInfo)
        {
            _custommessage = msg;
            _classname = classname;
            _scopeInfo = scopeInfo;
        }
    }
}
