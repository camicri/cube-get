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

public class SizeConverter
{
	public static string? convert(string? size)
	{
		if ( size == null )
			return "0 Bytes";
		
		string size_temp = size;
		if(size_temp.length <= 3)
			size_temp = size_temp + " bytes";
		else if(size_temp.length <= 6)
			size_temp = "%0.00f KB".printf(double.parse(size_temp)/1000.00);
		else if(size.length <= 9)
			size_temp = "%0.00f MB".printf(double.parse(size_temp)/1000000.00);
		else					
			size_temp = "%0.00f GB".printf(double.parse(size_temp)/1000000000.00);
		size_temp = size_temp.strip();
		return size_temp;
	}

	public static string add_sizes(Package[] pkgs)
	{
		long size = 0;
		foreach ( Package p in pkgs )
		{
			size += long.parse(p.size);
		}
		return convert(size.to_string());
	}
}

public class FileManager
{
	public static bool copy( string target, string destination )
	{
		File target_file = File.new_for_path(target);
		File destination_file  = File.new_for_path(destination);

		try
		{
			if ( !target_file.query_exists() )
				return false;
			
			target_file.copy ( destination_file , FileCopyFlags.OVERWRITE );
		}
		catch ( Error e )
		{
			stdout.printf("Error : %s\n", e.message);
			return false;
		}
		return true;
	}

	public static bool delete_directory (string target)
	{
		File target_file = File.new_for_path(target);

		if ( !target_file.query_exists() )
			return false;
		
		return true;
	}

	public static bool copy_directory_files ( string target , string destination , string? simple_regex_string = null) 
	{		
		var target_dir = File.new_for_path ( target );
		//var destination_dir = File.new_for_path ( destination );

		try
		{			
			var enumerator = target_dir.enumerate_children (FileAttribute.STANDARD_NAME, 0);		

			FileInfo file_info;
			while ( ( file_info = enumerator.next_file() ) != null )
			{								
				if ( file_info.get_file_type() == FileType.REGULAR )
				{
					string target_path = Path.build_filename ( target, file_info.get_name() );
					string destination_path = Path.build_filename ( destination, file_info.get_name() );
					bool to_copy = false;
					
					if ( simple_regex_string != null )
						to_copy = SimpleRegex.check (simple_regex_string, file_info.get_name() );
					else
						to_copy = true;

					if ( to_copy )
						copy ( target_path , destination_path );
				}
			}			
		}
		catch ( Error e )
		{
			stdout.printf("Error : %s\n", e.message);
			return false;
		}
		return true;
	}
}

public class SimpleRegex
{
	public static bool check(string simple_regex, string text)
	{
		string str = simple_regex;
		
		if (str == "*") //If all packages
			return true;
		else if ( !str.contains("*") ) //If not all packages. Exact package name
		{
			if ( str == text ) //If just specific package
				return true;
		}
		else if ( str.has_prefix("*") && str.has_suffix("*") ) //If contains
		{
			if( text.contains(str.replace("*","")) )
				return true;
		}
		else if ( str.has_prefix("*") ) //If ends with
		{
			if ( text.has_suffix(str.replace("*","")) )
				return true;
		}
		else if ( str.has_suffix("*") ) //If starts with
		{
			if( text.has_prefix(str.replace("*","")) )
				return true;
		}
		
		return false;
	}
}

public class ArgumentBuilder
{
	public static string[] convert(owned string arguments)
	{
		arguments = arguments.strip()+" ";
		ArrayList<string> arg_list = new ArrayList<string>();
		bool quote_flag = false;
		string arg = "";
		for ( int ctr = 0; ctr < arguments.length; ctr++ )	
		{
			char c = (char)arguments.get_char(ctr);
			if ( c == '\"' )
				quote_flag = !quote_flag;
			if ( c.isspace() && !quote_flag)
			{				
				arg_list.add(arg.strip());
				arg = "";
				continue;
			}			
			arg += c.to_string();
		}
		return arg_list.to_array();
	}
}

public class Compressor
{
	public static bool decompress( string source, string destination , BaseManager base_mgr)
	{
		string gzip_path = Which.which ("gzip", base_mgr);		
		string arguments = gzip_path + " -d " + source;
		int exit_code = 0;
		if ( (exit_code = ProcessManager.run_get_status(arguments.split(" "))) == 0)
		{
			try{
				var source_file = File.new_for_path(source.replace(".gz","").strip());
				var destination_file = File.new_for_path(destination);
				source_file.move(destination_file,FileCopyFlags.OVERWRITE);
			}catch (Error e)
			{
				stdout.printf("Error : %s\n",e.message);
				return false;
			}
		}
		else
		{
			stdout.printf("External Error : GZIP : %d\n",exit_code);
			return false;
		}
		return true;
	}
	
	/*
	public static bool compress( string source, string dest , ZlibCompressorFormat format)
	{
		return _convert ( File.new_for_path(source), File.new_for_path(dest), new ZlibCompressor(format) );
	}

	public static bool decompress( string source, string dest , ZlibCompressorFormat format)
	{
		return _convert ( File.new_for_path(source), File.new_for_path(dest), new ZlibDecompressor(format) );
	}

	private static bool _convert (File source, File dest, Converter converter)
	{
		try
		{
			var src_stream = source.read ();
			var dst_stream = dest.replace (null, false, 0);
			var conv_stream = new ConverterOutputStream (dst_stream, converter);
			// 'splice' pumps all data from an InputStream to an OutputStream
			conv_stream.splice (src_stream, 0);
		}
		catch ( Error e )
		{
			stdout.printf("Error : %s\n",e.message);
			return false;
		}
		return true;
	}
	*/
}

public class MD5Sum
{
	public static string get_md5 ( string filepath )
	{				
		Checksum checksum = new Checksum( ChecksumType.MD5 );

		FileStream stream = FileStream.open (filepath, "rb");				
		uint8 fbuf[100];
		size_t size;
		
		while ( ( size = stream.read( fbuf ) ) > 0 )
			checksum.update( fbuf, size );

		return checksum.get_string();
	}
}

public class Which
{
	public static string? which(owned string app_name, BaseManager _base_mgr)
	{		
		if ( SystemInformation.get_operating_system_type() == OperatingSystemType.WINDOWS )
			app_name = app_name + ".exe";
		
		string? path = Environment.find_program_in_path (app_name);			
		if ( path != null ) 
			return path;

		if ( File.new_for_path(Path.build_filename(_base_mgr.bin_directory,app_name)).query_exists() )
			return Path.build_filename(_base_mgr.bin_directory,app_name);
		else
			return null;		
	}
}