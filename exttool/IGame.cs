using System;
using System.Collections.Generic;

namespace Dev.YoshiRulz.MCTSHawkForDoug
{
	public abstract class GameBase<T>
		where T : Enum
	{
		/// <summary>faux-routine: yields 0 or more of <see langword="true"/> to request frameadvance, then yields a final <see langword="false"/> on completion</summary>
		private static readonly object DOCS_FAUXROUTINE = new();

		public abstract bool endFlag { get; set; }

		public abstract string name { get; }

		public abstract int rawscore { get; }

		public abstract int score { get; }

		public abstract bool ended();

		public abstract void expand(Node<T> p);

		public abstract IReadOnlyList<PossibleAction<T>> getActs();

		/// <seealso cref="DOCS_FAUXROUTINE"/>
		public abstract IEnumerable<bool> perform(PossibleAction<T> act, PossibleAction<T> act2 = default);

		/// <seealso cref="DOCS_FAUXROUTINE"/>
		public abstract IEnumerable<bool> rollout();

		/// <seealso cref="DOCS_FAUXROUTINE"/>
		protected IEnumerable<bool> waitFrames(int n)
		{
			for (var i = 0; i < n; i++) yield return true;
		}

		/// <seealso cref="DOCS_FAUXROUTINE"/>
		protected IEnumerable<bool> waitFramesBreak(int n)
		{
			for (var i = 0; i < n; i++)
			{
				yield return true;
				if (ended()) yield break;
			}
		}

		/// <seealso cref="DOCS_FAUXROUTINE"/>
		protected IEnumerable<bool> waitFrameBreak()
			=> waitFramesBreak(1);
	}
}
