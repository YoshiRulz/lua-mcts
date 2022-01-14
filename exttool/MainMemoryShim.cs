using BizHawk.Client.Common;

namespace Dev.YoshiRulz.MCTSHawkForDoug
{
	public readonly struct MainMemoryShim
	{
		private readonly string _d;

		private readonly IMemoryApi _memApi;

		public MainMemoryShim(IMemoryApi memApi)
		{
			_memApi = memApi;
			_d = _memApi.MainMemoryName;
		}

		public short read_s16_le(long addr)
		{
			_memApi.SetBigEndian(false);
			return (short) _memApi.ReadS16(addr, _d);
		}

		public byte readbyte(long addr)
			=> (byte) _memApi.ReadByte(addr, _d);

		public void writebyte(long addr, byte val)
			=> _memApi.WriteByte(addr, val, _d);
	}
}
