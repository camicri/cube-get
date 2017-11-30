/* -*- Mode: vala; tab-width: 4; intend-tabs-mode: t -*- */
/* cube-vala
 *
 * Copyright (C) Jake R. Capangpangan 2015 <camicrisystems@gmail.com>
	 *
 cube-vala is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
	 * 
	 * cube-vala is distributed in the hope that it will be useful, but
	 * WITHOUT ANY WARRANTY; without even the implied warranty of
	 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
	 * See the GNU General Public License for more details.
	 * 
	 * You should have received a copy of the GNU General Public License along
	 * with this program.  If not, see <http://www.gnu.org/licenses/>.
	 */

using Gee;

//namespace Cube
//{
public class DebianCompare
{
	public static int compare(owned string? ver1, owned string? ver2)
	{
		if ( ver1 == null || ver2 == null )
		{
			//stdout.printf ("No Version!\n");
			return 0;
		}

		ver1 = ver1.strip();
		ver2 = ver2.strip();

		//Make them in same size (Padded with spaces)
		if ( ver1.length > ver2.length )
			ver2 = @"%-$(ver1.length)s".printf(ver2);
		if ( ver2.length > ver1.length )
			ver1 = @"%-$(ver2.length)s".printf(ver1);

		VersionData ver_data1 = new VersionData(ver1);
		VersionData ver_data2 = new VersionData(ver2);

		if ( ver_data1.epoch > ver_data2.epoch )
			return 1;
		else if(ver_data1.epoch < ver_data2.epoch )
			return -1;			

		int ver_result = compare_version_string(ver_data1.version, ver_data2.version);			

		if ( ver_result != 0 )
			return ver_result;
		else
		{				
			return compare_version_string(ver_data1.revision, ver_data2.revision);
		}
	}

	public static int compare_version_string(owned string? s1, owned string? s2)
	{
		if ( s1 == null && s2 == null )
			return 0;
		else if ( s1 != null && s2 == null )
			return 1;
		else if ( s1 == null && s2 != null )
			return -1;

		//Make them in same size (Padded with spaces)
		if ( s1.length > s2.length )
			s2 = @"%-$(s1.length)s".printf(s2);
		if ( s2.length > s1.length )
			s1 = @"%-$(s2.length)s".printf(s1);			

		ArrayList<VersionTokenType> ver_type1 = new ArrayList<VersionTokenType>();
		ArrayList<VersionTokenType> ver_type2 = new ArrayList<VersionTokenType>();

		string str1 = "";
		string str2 = "";

		for ( int ctr = 0; ctr < s1.length; ctr++)
			ver_type1.add(new VersionTokenType(s1[ctr]));
		for ( int ctr = 0; ctr < s2.length; ctr++)
			ver_type2.add(new VersionTokenType(s2[ctr]));

		int i = 0;

		while ( i < ver_type1.size && i < ver_type2.size )
		{
			str1 = "";
			str2 = "";

			if ( strcmp(ver_type1[i].token_type, ver_type2[i].token_type) != 0)
			{
				if ( ver_type1[i].token_order > ver_type2[i].token_order )
					return 1;
				else
					return -1;
			}

			int j = i;
			string curr_type = ver_type1[i].token_type;
			while ( j < ver_type1.size && ver_type1[j].token_type == curr_type )
				j += 1;


			for ( int ctr = i; ctr < j; ctr++ )
				str1 += ver_type1[ctr].token.to_string();

			j = i;

			while ( j < ver_type2.size && ver_type2[j].token_type == curr_type )
				j += 1;

			for ( int ctr = i; ctr < j; ctr++)
				str2 += ver_type2[ctr].token.to_string();

			i = j;

			if( curr_type == "digit" && str1.length != str2.length )
			{
				int int1 = int.parse(str1);
				int int2 = int.parse(str2);

				if ( int1 > int2 )
					return 1;
				else
					return -1;
			}				

			int result = strcmp(str1, str2);

			if ( result != 0 )
			{
				if ( result > 0 )
					return 1;
				else
					return -1;
			}
		}

		if ( strcmp(s1, s2) == 1 )
			return 1;
		else if ( strcmp(s1, s2) == -1 )
			return -1;
		return 0;
	}

	public static bool compare_equality_string(string? ver1, string? ver2, owned string? eq_operator)
	{
		int comp_result = compare(ver1, ver2);
		bool result = false;		

		if ( eq_operator == null )
			return true;

		eq_operator.strip();

		if ( eq_operator.length == 0 )
			result = true;
		else if ( eq_operator == "=" )
		{
			if ( comp_result == 0 )
				return true;
		}
		else if ( eq_operator == ">>" )
		{
			if ( comp_result > 0 )
				return true;
		}
		else if ( eq_operator == "<<" )
		{
			if ( comp_result < 0 )
				return true;
		}
		else if ( eq_operator == ">=" )
		{
			if ( comp_result >= 0 )
				return true;
		}
		else if ( eq_operator == "<=" )
		{
			if ( comp_result <= 0 )
				return true;
		}

		return result;
	}

	public class VersionData
	{
		public int epoch { get; set; default = 0; }
		public string version { get; set; default = null; }
		public string revision { get; set; default = null; }

		public VersionData(owned string? raw_version)
		{
			string[] arr_epoch;

			if ( raw_version.contains(":") )
				arr_epoch = raw_version.split(":",2);
			else
				arr_epoch = new string[]{raw_version};

			if ( arr_epoch.length > 1 )
			{
				epoch = int.parse(arr_epoch[0]);
				if ( epoch < 0 || epoch > 10 )
					return ; //Invalid epoch
			}
			else
			{
				this.epoch = 0;
				arr_epoch[0] = "0";
				raw_version = "0:" + raw_version;
			}

			string[] arr_version;
			if ( raw_version.contains("-") )
				arr_version = raw_version.split(":",-1)[1].split("-",2);
			else
				arr_version = new string[]{raw_version.split(":",-1)[1]};

			if ( arr_version.length > 1 )
			{
				this.revision = arr_version[arr_version.length - 1];
				this.version = arr_version[0];
			}
			else
			{
				this.revision = null;
				this.version = arr_version[0];
			}				
		}
	}

	public class VersionTokenType
	{
		public char? token { get; set; default = null; }

		public VersionTokenType(char tok)
		{
			token = tok;
		}

		public string token_type
		{
			get
			{
				if ( token.isalpha() )
					return "alpha";
				else if ( token.isdigit() )
					return "digit";
				else if ( token == '~' )
					return "tilde";
				else
					return "delimit";
			}
		}

		public int token_order
		{
			get
			{
				if ( token == '~' )
					return -1;
				else if ( token.isdigit() )
					return 0;
				else if ( token == null )
					return 0;
				else if ( token.isalpha() || token.isspace() )
					return (int)token;
				else
					return (int)token + 256;					
			}
		}
	}
}
//}
