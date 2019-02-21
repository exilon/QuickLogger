using QuickLogger.NetStandard.Abstractions;

namespace QuickLogger.NetStandard.Abstractions
{
    public interface ILoggerConfigManager
    {
        ILoggerSettings Load();
        ILoggerSettings Reset();
        ILoggerSettings GetSettings();
        void Write();
    }
}
