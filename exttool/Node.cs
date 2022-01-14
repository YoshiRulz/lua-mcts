using System;
using System.Collections.Generic;

namespace Dev.YoshiRulz.MCTSHawkForDoug
{
	public class Node<T>
		where T : Enum
	{
		public PossibleAction<T> action = default;

		public IDictionary<string, Node<T>>? children = null;

		public int cn = 0;

		public string? name;

		public Node<T>? parent = null;

		public string? state = null;

		public bool terminal = false;

		public int terminalChildren = 0;

		public int value = 0;

		public int visits = 0;

		public Node(string? n)
			=> name = n;
	}
}
