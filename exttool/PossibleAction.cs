using System;

namespace Dev.YoshiRulz.MCTSHawkForDoug
{
	public readonly struct PossibleAction<T>
		where T : Enum
	{
		public readonly string id;

		public readonly T name;

		public readonly (byte, byte)? Position;

		public PossibleAction(string id, T name, (byte, byte)? pos = null)
		{
			this.id = id;
			this.name = name;
			Position = pos;
		}
	}
}
