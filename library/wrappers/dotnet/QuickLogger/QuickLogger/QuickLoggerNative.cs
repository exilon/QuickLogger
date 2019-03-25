using System;
using System.Linq;
using System.Runtime.InteropServices;
using QuickLogger.NetStandard.Abstractions;
using Newtonsoft.Json;
using NativeLibraryLoader;
using System.IO;
using System.Reflection;
using System.Security.Permissions;

namespace QuickLogger.NetStandard
{
    [SecurityPermission(SecurityAction.Demand, Flags = SecurityPermissionFlag.ControlAppDomain)]
    public class QuickLoggerNative : ILogger, IDisposable
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
        private delegate void EnableProviderNative(string providerName);
        [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        private delegate void DisableProviderNative(string providerName);
        [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        private delegate int GetLibVersionNative(out string str);        
        [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        private delegate int GetProviderNamesNative(out string str);
        [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        private delegate void TestCallbacksNative();
        [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        private delegate int GetLastErrorNative(out string str);

        //Native Library native function pointers 
        private static AddProviderJSONNative addProviderJSONNative;
        private static RemoveProviderNative removeProviderNative;
        private static AddWrapperStatusChangedDelegateNative addWrapperStatusChangedDelegateNative;
        private static AddWrapperSendLimitsDelegateNative addWrapperSendLimitsDelegateNative;
        private static AddWrapperCriticalErrorDelegateNative addWrapperCriticalErrorDelegateNative;
        private static AddWrapperQueueErrorDelegateNative addWrapperQueueErrorDelegateNative;
        private static AddWrapperRestartDelegateNative addWrapperRestartDelegateNative;
        private static AddWrapperStartDelegateNative addWrapperStartDelegateNative;
        private static AddWrapperFailDelegateNative addWrapperFailDelegateNative;
        private static AddWrapperErrorDelegateNative addWrapperErrorDelegateNative;
        private static AddStandardConsoleProviderNative addStandardConsoleProviderNative;
        private static AddStandardFileProviderNative addStandardFileProviderNative;
        private static TestCallbacksNative testCallbacksNative;
        private static InfoNative infoNative;
        private static WarningNative warningNative;
        private static ErrorNative errorNative;
        private static TraceNative traceNative;
        private static CustomNative customNative;
        private static SuccessNative successNative;
        private static EnableProviderNative enableProviderNative;
        private static DisableProviderNative disableProviderNative;
        private static GetLibVersionNative getLibVersion;
        private static GetProviderNamesNative getProviderNamesNative;
        private static GetLastErrorNative getLastErrorNative;
        private static UnhandledExceptionEventHandler unhandledEventHandler;
        private NativeLibrary _quickloggerlib;
        private string _rootPath;
        private string[] libNames = { "\\x64\\QuickLogger.dll", "\\x86\\QuickLogger.dll", "\\x64\\libquicklogger.so", "\\x86\\libquicklogger.so" };

        public QuickLoggerNative(string rootPath, bool handleExceptions = true )
        {            
            if (string.IsNullOrEmpty(rootPath)) { _rootPath = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location); }
            else { _rootPath = rootPath; }
            for (int x = 0; x < libNames.Count(); x++) { libNames[x] = _rootPath + libNames[x]; }
            _quickloggerlib = new NativeLibrary(libNames);
            MapFunctionPointers();
            if (handleExceptions) { setupCurrentDomainExceptionHandler(); }
        }

        ~QuickLoggerNative() { Dispose(); }

        private void setupCurrentDomainExceptionHandler()
        {
            AppDomain currentDomain = AppDomain.CurrentDomain;
            unhandledEventHandler = new UnhandledExceptionEventHandler(OnUnhandledException);
            currentDomain.UnhandledException += unhandledEventHandler;
        }

        private void OnUnhandledException(object sender, UnhandledExceptionEventArgs e)
        {
            if (e.ExceptionObject is Exception) { Error((Exception)e.ExceptionObject); }
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
            disableProviderNative = _quickloggerlib.LoadFunction<DisableProviderNative>("DisableProviderNative");
            enableProviderNative = _quickloggerlib.LoadFunction<EnableProviderNative>("EnableProviderNative");            
            getLibVersion = _quickloggerlib.LoadFunction<GetLibVersionNative>("GetLibVersionNative");
            getProviderNamesNative = _quickloggerlib.LoadFunction<GetProviderNamesNative>("GetProviderNamesNative");
            getLastErrorNative = _quickloggerlib.LoadFunction<GetLastErrorNative>("GetLastError");
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
            if (GetLoggerProviderTypes().Where(x => x.ToLower() == provider.getProviderProperties().GetProviderType().ToLower()).Count() == 0) { throw new Exception("Invalid provider type." + GetLastError()); }
            if (!(provider is ILoggerProvider)) { throw new TypeLoadException("Invalid Provider"); }
            if (!Convert.ToBoolean(addProviderJSONNative?.Invoke(provider.getProviderProperties().ToJSON()))) { throw new TypeLoadException("Error while adding a provider to native library " + GetLastError()); }
            AssignDelegatesToNative(provider);
        }
        public void RemoveProvider(ILoggerProvider provider)
        {
            if (!(provider is ILoggerProvider)) { throw new TypeLoadException("Invalid Provider"); }
            if (!Convert.ToBoolean(removeProviderNative?.Invoke(provider.getProviderProperties().GetProviderName()))) { throw new TypeLoadException("Error while removing a provider to native library " + GetLastError()); }
        }
        public void RemoveProvider(string name)
        {
            if (!Convert.ToBoolean(removeProviderNative(name))) { throw new TypeLoadException("Error while removing a provider to native library " + GetLastError()); }
        }
        public void InitStandardConsoleProvider()
        {
            AddProvider(QuickLoggerBuiltInStandardProviders.CreateStandardConsoleProvider());
        }
        public void InitStandardFileProvider(string FilePath)
        {
            AddProvider(QuickLoggerBuiltInStandardProviders.CreateStandardFileProvider(FilePath));
        }

        public void AddStandardConsoleProvider()
        {
            addStandardConsoleProviderNative();
        }

        public void AddStandardFileProvider(string FileName)
        {
            addStandardFileProviderNative(FileName);
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

        public void TestCallbacks()
        {
            testCallbacksNative?.Invoke();
        }

        public string GetLastError()
        {
            string lasterror = "";
            getLastErrorNative(out lasterror);
            return lasterror;
        }

        public void EnableProvider(ILoggerProvider provider)
        {           
            enableProviderNative?.Invoke(provider.getProviderProperties().GetProviderName()); 
        }

        public void EnableProvider(string name)
        {
            enableProviderNative?.Invoke(name);
        }

        public void DisableProvider(ILoggerProvider provider)
        {
            disableProviderNative?.Invoke(provider.getProviderProperties().GetProviderName());
        }

        public void DisableProvider(string name)
        {
            disableProviderNative?.Invoke(name);
        }

        public void Dispose()
        {
            GC.SuppressFinalize(this);
        }
    }
}
