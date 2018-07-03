using Newtonsoft.Json;
using QuickLogger.NetStandard.Abstractions;
using System;
using System.Collections.Generic;
using static QuickLogger.NetStandard.Abstractions.LoggerEventTypes;

namespace QuickLogger.NetStandard
{
    public class ILoggerProviderTypeConverter : JsonConverter
    {
        public override bool CanConvert(Type objectType)
        {
            return objectType == typeof(ILoggerProvider);
        }

        public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer)
        {
            return serializer.Deserialize(reader, typeof(QuickLoggerProvider));
        }

        public override void WriteJson(JsonWriter writer, object value, JsonSerializer serializer)
        {
            serializer.Serialize(writer, typeof(ILoggerProvider));
        }
    }

    public class ILoggerProviderPropsTypeConverter : JsonConverter
    {
        public override bool CanConvert(Type objectType)
        {
            return objectType == typeof(ILoggerProviderProps);
        }

        public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer)
        {
            return serializer.Deserialize(reader, typeof(QuickLoggerProviderProps));
        }

        public override void WriteJson(JsonWriter writer, object value, JsonSerializer serializer)
        {
            serializer.Serialize(writer, typeof(ILoggerProviderProps));
        }
    }

    public class ILoggerLoggerTypeConverter : JsonConverter
    {
        public override bool CanConvert(Type objectType)
        {
            return objectType == typeof(LoggerEventTypes.EventType);
        }

        public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer)
        {
            return serializer.Deserialize(reader, typeof(LoggerEventTypes.EventType));
        }

        public override void WriteJson(JsonWriter writer, object value, JsonSerializer serializer)
        {  
            serializer.Serialize(writer, Enum.GetName(typeof(LoggerEventTypes.EventType), value));
        }
    }

    public class ILoggerHashSetTypeConverter : JsonConverter
    {
        public override bool CanConvert(Type objectType)
        {
            return objectType == typeof(HashSet<EventType>);
        }

        public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer)
        {            
            string[] ets = ((string)reader.Value).Replace("[", "").Replace("]", "").Split(',');
            HashSet<EventType> eventTypes = new HashSet<EventType>();
            EventType a = 0;
            foreach (string et in ets)
            {                
                if (Enum.TryParse(et, out a)) { eventTypes.Add(a); }
            }
            return eventTypes;
        }

        public override void WriteJson(JsonWriter writer, object value, JsonSerializer serializer)
        {            
            string ets = string.Join(",", ((HashSet<EventType>)value));
            ets = ets.Insert(0, "[");
            ets = ets.Insert(ets.Length, "]");
            serializer.Serialize(writer, ets);
        }
    }
}
