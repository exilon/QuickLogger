using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Threading;

namespace QuickLogger.Extensions.NetCore
{
    internal static class CallContext<T>
    {


        static ConcurrentDictionary<Guid, AsyncLocal<T>> state = new ConcurrentDictionary<Guid, AsyncLocal<T>>();


        /// <summary>
        /// Stores a given object and associates it with the specified name.
        /// </summary>
        /// <param name="id">The name with which to associate the new item in the call context.</param>
        /// <param name="data">The object to store in the call context.</param>
        public static void SetData(Guid id, T data) =>
            state.GetOrAdd(id, _ => new AsyncLocal<T>()).Value = data;


        /// <summary>
        /// Retrieves an object with the specified name from the <see cref="CallContext"/>.
        /// </summary>
        /// <typeparam name="T">The type of the data being retrieved. Must match the type used when the <paramref name="id"/> was set via <see cref="SetData{T}(string, T)"/>.</typeparam>
        /// <param name="id">The name of the item in the call context.</param>
        /// <returns>The object in the call context associated with the specified name, or a default value for <typeparamref name="T"/> if none is found.</returns>
        public static T GetData(Guid id) =>
            state.TryGetValue(id, out AsyncLocal<T> data) ? data.Value : default(T);


        /// <summary>
        /// Retrieves all stored objects.
        /// </summary>
        public static ICollection<AsyncLocal<T>> GetAll() => state.Values;


        /// <summary>
        /// Removes a given object.
        /// </summary>
        /// <param name="id">The name with which to associate the new item in the call context.</param>
        public static void RemoveData(Guid id, out AsyncLocal<T> data) =>
            state.TryRemove(id, out data);
    }
}
