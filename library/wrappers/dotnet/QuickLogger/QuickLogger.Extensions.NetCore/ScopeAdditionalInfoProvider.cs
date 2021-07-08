using System;
using System.Collections.Generic;
using System.Text;
using QuickLogger.Extensions.Wrapper.Application.Services;

namespace QuickLogger.Extensions.NetCore
{
    public class ScopeAdditionalInfoProvider : IAdditionalLoggerInfoProviderService
    {
        public object GetAdditionalInfo()
        {
            var scopes = CallContext<Scope<IDictionary<string, object>>>.GetAll();

            return scopes;
        }
    }
}
