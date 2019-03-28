using System;
using System.Linq;
using System.Collections.Generic;
using Newtonsoft.Json;
using QuickLogger.NetStandard.Abstractions;

namespace QuickLogger.NetStandard
{
    public class QuickLoggerProvider : ILoggerProvider
    {
        private ILoggerProviderProps _providerProps { get; set; }
        public ILoggerProviderProps providerProps { get { return _providerProps; } }
        public QuickLoggerProvider(ILoggerProviderProps providerProps)
        {
            _providerProps = providerProps;                        
        }

        public event ProviderStartEventHandler Started;
        public event ProviderStatusChangedEventHandler StatusChanged;
        public event ProviderErrorEventHandler Error;
        public event ProviderQueueErrorEventHandler QueueError;
        public event ProviderCriticalErrorEventHandler CriticalError;
        public event ProviderRestartEventHandler Restarted;
        public event ProviderSendLimits SendLimitsReached;
        public event ProviderFailToLog FailToLog;

        public ILoggerProviderProps getProviderProperties()
        {
            return _providerProps;
        }

        public void OnStarted(string msg)
        {
            Started?.Invoke(msg);
        }

        public void OnStatusChanged(string msg)
        {
            StatusChanged?.Invoke(msg);
        }

        public void OnError(string msg)
        {
            Error?.Invoke(msg);
        }

        public void OnQueueError(string msg)
        {
            QueueError?.Invoke(msg);
        }

        public void OnCriticalError(string msg)
        {
            CriticalError?.Invoke(msg);
        }

        public void OnRestart(string msg)
        {
            Restarted?.Invoke(msg);
        }

        public void OnSendLimitsReached()
        {
            SendLimitsReached?.Invoke();
        }

        public void OnFailToLog()
        {
            FailToLog?.Invoke();
        }
    }
}
