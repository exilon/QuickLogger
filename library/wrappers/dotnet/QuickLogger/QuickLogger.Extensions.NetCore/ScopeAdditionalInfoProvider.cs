using System;
using System.Collections;
using QuickLogger.Extensions.Wrapper.Application.Services;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;

namespace QuickLogger.Extensions.NetCore
{
    class DictionaryAsArrayResolver : DefaultContractResolver
    {
        protected override JsonContract CreateContract(Type objectType)
        {
            if (objectType.GetInterfaces().Any(i => i == typeof(IDictionary) ||
                                                    (i.IsGenericType && i.GetGenericTypeDefinition() == typeof(IDictionary<,>))))
            {
                return base.CreateArrayContract(objectType);
            }

            return base.CreateContract(objectType);
        }
    }


    public class ScopeInfoProvider : IScopeInfoProviderService
    {

        public object GetScopeInfo()
        {
            var scopes = CallContext<Scope<IDictionary<string, object>>>.GetAll();

            var scope = scopes.FirstOrDefault();


            //JsonSerializerSettings settings = new JsonSerializerSettings();

            //string json = JsonConvert.SerializeObject(, settings);

            return scope?.Value?.State;
        }
    }
}
