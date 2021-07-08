using System;
using System.Collections.Generic;

namespace QuickLogger.Extensions.NetCore
{
    internal class Scope<TState> : IDisposable
    {


        public Guid Id { get; private set; }
        public TState State { get; private set; }


        internal Scope(TState state)
        {
            Id = Guid.NewGuid();
            State = state;
        }


        public static IDisposable CreateScope(TState state) 
        {
            var scope = new Scope<IDictionary<string, object>>(state as IDictionary<string, object>);

            CallContext<Scope<IDictionary<string, object>>>.SetData(scope.Id, scope);

            return scope;
        }


        public void Dispose()
        {
            CallContext<Scope<IDictionary<string, object>>>.RemoveData(Id, out var state);

            state?.Value.Dispose();
            State = default(TState);
        }
    }
}
