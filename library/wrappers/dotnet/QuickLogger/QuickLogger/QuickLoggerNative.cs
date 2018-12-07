using System;
using System.Linq;
using System.Runtime.InteropServices;
using System.Collections.Generic;
using QuickLogger.NetStandard.Abstractions;
using Newtonsoft.Json;
using NativeLibraryLoader;
using System.IO;
using System.Reflection;

namespace QuickLogger.NetStandard
{
    public class QuickLoggerNative : ILogger
    {
        //Native Library native function types 
        [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        private delegate int AddProviderJSONNative(string serializedProvider);
        [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        private delegate int RemoveProviderNative(string name);
        [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        private delegate void AddWrapperStatusChangedDelegateNative(string providerName, IntPtr callback);
        [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        private delegate void AddWrapperSendLimitsDelegateNative(string providerName, IntPtr callback);
        [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        private delegate void AddWrapperCriticalErrorDelegateNative(string providerName, IntPtr callback);
        [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        private delegate void AddWrapperQueueErrorDelegateNative(string providerName, IntPtr callback);
        [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        private delegate void AddWrapperRestartDelegateNative(string providerName, IntPtr callback);
        [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        private delegate void AddWrapperStartDelegateNative(string providerName, IntPtr callback);
        [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        private delegate void AddWrapperFailDelegateNative(string providerName, IntPtr callback);
        [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        private delegate void AddWrapperErrorDelegateNative(string providerName, IntPtr callback);
        [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        private delegate int AddStandardConsoleProviderNative();
        [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        private delegate void AddStandardFileProviderNative(string FileName);
        [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        private delegate void InfoNative(string message);
        [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        private delegate void SuccessNative(string message);
        [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        private delegate void WarningNative(string message);
        [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        private delegate void ErrorNative(string message);
        [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        private delegate void TraceNative(string message);
        [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        private delegate void CustomNative(string message);
        [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        private delegate int GetLibVersionNative(out string str);
        [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        private delegate int GetProviderNamesNative(out string str);
        [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        private delegate void TestCallbacksNative();

        //Native Library native function pointers 
        private AddProviderJSONNative addProviderJSONNative;
        private RemoveProviderNative removeProviderNative;
        private AddWrapperStatusChangedDelegateNative addWrapperStatusChangedDelegateNative;
        private AddWrapperSendLimitsDelegateNative addWrapperSendLimitsDelegateNative;
        private AddWrapperCriticalErrorDelegateNative addWrapperCriticalErrorDelegateNative;
        private AddWrapperQueueErrorDelegateNative addWrapperQueueErrorDelegateNative;
        private AddWrapperRestartDelegateNative addWrapperRestartDelegateNative;
        private AddWrapperStartDelegateNative addWrapperStartDelegateNative;
        private AddWrapperFailDelegateNative addWrapperFailDelegateNative;
        private AddWrapperErrorDelegateNative addWrapperErrorDelegateNative;
        private AddStandardConsoleProviderNative addStandardConsoleProviderNative;
        private AddStandardFileProviderNative addStandardFileProviderNative;
        private TestCallbacksNative testCallbacksNative;
        private InfoNative infoNative;
        private WarningNative warningNative;
        private ErrorNative errorNative;
        private TraceNative traceNative;
        private CustomNative customNative;
        private SuccessNative successNative;
        private GetLibVersionNative getLibVersion;
        private GetProviderNamesNative getProviderNamesNative;

        private readonly ILoggerConfigManager _configManager;
        private ILoggerSettings _settings;
        private NativeLibrary _quickloggerlib;
        private string _rootPath;
        private string[] libNames = { "\\x64\\QuickLogger.dll", "\\x86\\QuickLogger.dll", "\\x64\\libquicklogger.so", "\\x86\\libquicklogger.so" };

        public QuickLoggerNative(ILoggerConfigManager configManager, string rootPath)
        {
            if (string.IsNullOrEmpty(rootPath)) { _rootPath = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location); }
            else { _rootPath = rootPath; }
            for (int x = 0; x < libNames.Count(); x++) { libNames[x] = _rootPath + libNames[x]; }
            _configManager = configManager;
            _quickloggerlib = new NativeLibrary(libNames);             
            MapFunctionPointers();            
        }

        public QuickLoggerNative(string rootPath)
        {            
            if (string.IsNullOrEmpty(rootPath)) { _rootPath = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location); }
            else { _rootPath = rootPath; }
            for (int x = 0; x < libNames.Count(); x++) { libNames[x] = _rootPath + libNames[x]; }
            _quickloggerlib = new NativeLibrary(libNames);
            MapFunctionPointers();
        }

        ~QuickLoggerNative()
        {
            if (_quickloggerlib != null) { _quickloggerlib.Dispose(); }
        }

        private void MapFunctionPointers()
        {
            addProviderJSONNative = _quickloggerlib.LoadFunction<AddProviderJSONNative>("AddProviderJSONNative");
            removeProviderNative = _quickloggerlib.LoadFunction<RemoveProviderNative>("RemoveProviderNative");            
            addWrapperStatusChangedDelegateNative = _quickloggerlib.LoadFunction<AddWrapperStatusChangedDelegateNative>("AddWrapperStatusChangedDelegateNative");
            addWrapperSendLimitsDelegateNative = _quickloggerlib.LoadFunction<AddWrapperSendLimitsDelegateNative>("AddWrapperSendLimitsDelegateNative");
            addWrapperCriticalErrorDelegateNative = _quickloggerlib.LoadFunction<AddWrapperCriticalErrorDelegateNative>("AddWrapperCriticalErrorDelegateNative");
            addWrapperQueueErrorDelegateNative = _quickloggerlib.LoadFunction<AddWrapperQueueErrorDelegateNative>("AddWrapperQueueErrorDelegateNative");
            addWrapperRestartDelegateNative = _quickloggerlib.LoadFunction<AddWrapperRestartDelegateNative>("AddWrapperRestartDelegateNative");
            addWrapperStartDelegateNative = _quickloggerlib.LoadFunction<AddWrapperStartDelegateNative>("AddWrapperStartDelegateNative");
            addWrapperFailDelegateNative = _quickloggerlib.LoadFunction<AddWrapperFailDelegateNative>("AddWrapperFailDelegateNative");
            addStandardConsoleProviderNative = _quickloggerlib.LoadFunction<AddStandardConsoleProviderNative>("AddStandardConsoleProviderNative");
            addStandardFileProviderNative = _quickloggerlib.LoadFunction<AddStandardFileProviderNative>("AddStandardFileProviderNative");
            addWrapperErrorDelegateNative = _quickloggerlib.LoadFunction<AddWrapperErrorDelegateNative>("AddWrapperErrorDelegateNative");
            testCallbacksNative = _quickloggerlib.LoadFunction<TestCallbacksNative>("TestCallbacksNative");
            infoNative = _quickloggerlib.LoadFunction<InfoNative>("InfoNative");
            warningNative = _quickloggerlib.LoadFunction<WarningNative>("WarningNative");
            errorNative = _quickloggerlib.LoadFunction<ErrorNative>("ErrorNative");
            traceNative = _quickloggerlib.LoadFunction<TraceNative>("TraceNative");
            customNative = _quickloggerlib.LoadFunction<CustomNative>("CustomNative");
            successNative = _quickloggerlib.LoadFunction<SuccessNative>("SuccessNative");
            getLibVersion = _quickloggerlib.LoadFunction<GetLibVersionNative>("GetLibVersionNative");
            getProviderNamesNative = _quickloggerlib.LoadFunction<GetProviderNamesNative>("GetProviderNamesNative");
        }
        private Dictionary<string, string> BuildBaseLogEvent(string message, string level)
        {
            return new Dictionary<string, string>{
                { "@timestamp", DateTimeOffset.Now.UtcDateTime.ToString("O") },
                { "type", "logevent" },
                { "environment", _settings.getEnvironment() },
                { "message", message },
                { "level", level }
                };
        }
        private string BuildExceptionEvent(Exception exception, string level, object correlatedId = null, string message = "")
        {
            var logevent = BuildLogEvent(message, level, correlatedId);

            logevent.Add("exception", exception.GetType().ToString());

            if (!string.IsNullOrWhiteSpace(exception.Source))
                logevent.Add("source", exception.Source);

            if (!string.IsNullOrWhiteSpace(exception.StackTrace))
                logevent.Add("stackTrace", exception.StackTrace);

            if (exception.TargetSite != null)
                logevent.Add("targetSite", exception.TargetSite.ToString());

            return JsonConvert.SerializeObject(logevent);
        }
        private Dictionary<string, string> BuildLogEvent(string message, string level, object correlatedId = null)
        {
            var logevent = BuildBaseLogEvent(message, level);

            if (correlatedId != null)
                logevent.Add("correlatedId", correlatedId.ToString());

            return logevent;
        }
        private Dictionary<string, string> BuildKpiEvent(string name, string value, object correlatedId = null)
        {
            var logevent = BuildLogEvent(name + " - " + value, "KPI");

            logevent.Add("kpi", name);

            logevent.Add("value", value);

            return logevent;
        }
        public void Custom(string message)
        {
            customNative?.Invoke(message);                        
        }
        public void Success(string message)
        {
            successNative?.Invoke(message);
        }
        public void Error(string message)
        {
            errorNative?.Invoke(message);
        }
        public void Info(string message)
        {
            infoNative?.Invoke(message);
        }
        public void Trace(string message)
        {
            traceNative?.Invoke(message);                       
        }
        public void Warning(string message)
        {
            warningNative?.Invoke(message);            
        }
        public void Error(Exception exception)
        {
            errorNative?.Invoke(exception.Message);            
        }
        public void KPI(string name, string value)
        {
            throw new NotImplementedException();
        }

        private void AssignDelegatesToNative(ILoggerProvider provider)
        {
            addWrapperErrorDelegateNative?.Invoke(provider.getProviderProperties().GetProviderName(), Marshal.GetFunctionPointerForDelegate(new ProviderErrorEventHandler(provider.OnError)));
            addWrapperFailDelegateNative?.Invoke(provider.getProviderProperties().GetProviderName(), Marshal.GetFunctionPointerForDelegate(new ProviderFailToLog(provider.OnFaliToLog)));
            addWrapperCriticalErrorDelegateNative?.Invoke(provider.getProviderProperties().GetProviderName(), Marshal.GetFunctionPointerForDelegate(new ProviderCriticalErrorEventHandler(provider.OnCriticalError)));
            addWrapperQueueErrorDelegateNative?.Invoke(provider.getProviderProperties().GetProviderName(), Marshal.GetFunctionPointerForDelegate(new ProviderQueueErrorEventHandler(provider.OnQueueError)));
            addWrapperRestartDelegateNative?.Invoke(provider.getProviderProperties().GetProviderName(), Marshal.GetFunctionPointerForDelegate(new ProviderRestartEventHandler(provider.OnRestart)));
            addWrapperSendLimitsDelegateNative?.Invoke(provider.getProviderProperties().GetProviderName(), Marshal.GetFunctionPointerForDelegate(new ProviderSendLimits(provider.OnSendLimitsReached)));
            addWrapperStartDelegateNative?.Invoke(provider.getProviderProperties().GetProviderName(), Marshal.GetFunctionPointerForDelegate(new ProviderStartEventHandler(provider.OnStarted)));
            addWrapperStatusChangedDelegateNative?.Invoke(provider.getProviderProperties().GetProviderName(), Marshal.GetFunctionPointerForDelegate(new ProviderStatusChangedEventHandler(provider.OnStatusChanged)));
        }
        public void AddProvider(ILoggerProvider provider)
        {
            if (GetLoggerProviderTypes().Where(x => x.ToLower() == provider.getProviderProperties().GetProviderType().ToLower()).Count() == 0) { throw new Exception("Invalid provider type."); }
            if (!(provider is ILoggerProvider)) { throw new TypeLoadException("Invalid Provider"); }
            if (!Convert.ToBoolean(addProviderJSONNative?.Invoke(provider.getProviderProperties().ToJSON()))) { throw new TypeLoadException("Error while adding a provider to native library"); }
            AssignDelegatesToNative(provider);
        }
        public void RemoveProvider(ILoggerProvider provider)
        {
            if (!(provider is ILoggerProvider)) { throw new TypeLoadException("Invalid Provider"); }
            if (!Convert.ToBoolean(removeProviderNative?.Invoke(provider.getProviderProperties().GetProviderName()))) { throw new TypeLoadException("Error while removing a provider to native library"); }
        }
        public void RemoveProvider(string name)
        {
            if (!Convert.ToBoolean(removeProviderNative(name))) { throw new TypeLoadException("Error while removing a provider to native library"); }
        }
        public void InitStandardConsoleProvider()
        {
            AddProvider(QuickLoggerBuiltInStandardProviders.CreateStandardConsoleProvider());
        }
        public void InitStandardFileProvider(string FilePath)
        {
            AddProvider(QuickLoggerBuiltInStandardProviders.CreateStandardFileProvider(FilePath));
        }
        public void InitializeConfiguration()
        {
            if (_configManager != null)
            {
                _settings = _configManager.Load();
                _settings.Providers().ForEach(x => AddProvider(x));
            }
        }

        public void AddStandardConsoleProvider()
        {
            addStandardConsoleProviderNative();
        }

        public void AddStandardFileProvider(string FileName)
        {
            addStandardFileProviderNative(FileName);
        }

        public void ReloadConfig()
        {
            if (_configManager != null)
                _settings = _configManager.Load();
        }

        public void Reload()
        {
            throw new NotImplementedException();
        }

        public string[] GetLoggerProviderTypes()
        {
            string types = "";
            getProviderNamesNative(out types);
            return JsonConvert.DeserializeObject<string[]>(types);
        }

        public string GetLoggerNameAndVersion()
        {
            string version = "";
            getLibVersion(out version);
            return version;
        }

        public void EnableProvider(string name)
        {
            throw new NotImplementedException();
        }

        public void DisableProvider(string name)
        {
            throw new NotImplementedException();
        }

        void ILogger.TestCallbacks()
        {
            testCallbacksNative?.Invoke();
        }
    }
}
