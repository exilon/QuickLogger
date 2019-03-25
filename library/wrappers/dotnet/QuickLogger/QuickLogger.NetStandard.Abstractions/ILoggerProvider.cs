using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace QuickLogger.NetStandard.Abstractions
{
    public delegate void ProviderStartEventHandler([MarshalAs(UnmanagedType.LPWStr)] string msg);
    public delegate void ProviderStatusChangedEventHandler([MarshalAs(UnmanagedType.LPWStr)] string msg);
    public delegate void ProviderErrorEventHandler([MarshalAs(UnmanagedType.LPWStr)] string msg);
    public delegate void ProviderQueueErrorEventHandler([MarshalAs(UnmanagedType.LPWStr)] string msg);
    public delegate void ProviderRestartEventHandler([MarshalAs(UnmanagedType.LPWStr)] string msg);
    public delegate void ProviderCriticalErrorEventHandler([MarshalAs(UnmanagedType.LPWStr)] string msg);
    public delegate void ProviderSendLimits();
    public delegate void ProviderFailToLog();

    public interface ILoggerProvider
    {
        event ProviderStartEventHandler Started;
        void OnStarted(string msg);
        event ProviderStatusChangedEventHandler StatusChanged;
        void OnStatusChanged(string msg);
        event ProviderErrorEventHandler Error;
        void OnError(string msg);
        event ProviderQueueErrorEventHandler QueueError;
        void OnQueueError(string msg);
        event ProviderCriticalErrorEventHandler CriticalError;
        void OnCriticalError(string msg);
        event ProviderSendLimits SendLimitsReached;
        void OnSendLimitsReached();
        event ProviderRestartEventHandler Restarted;
        void OnRestart(string msg);
        event ProviderFailToLog FailToLog;
        void OnFailToLog();
        ILoggerProviderProps getProviderProperties();
    }
}
