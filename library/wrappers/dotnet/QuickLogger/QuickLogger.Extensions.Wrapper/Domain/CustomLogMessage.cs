using System;
using System.Collections.Generic;
using System.Text;

namespace QuickLogger.Extensions.Wrapper.Domain
{
    public class CustomLogMessage
    {
        private object _additionalinfo;
        private string _custommessage;
        private string _classname;

        public string ClassName { get { return _classname; } }
        public string CustomMessage { get { return _custommessage; } }
        public object AdditionalInfo { get { return _additionalinfo; } }

        public CustomLogMessage(string classname, string msg, object additionalinfo)
        {
            _custommessage = msg;
            _classname = classname;
            _additionalinfo = additionalinfo;
        }
    }
}
