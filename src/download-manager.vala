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

public enum DownloadStatusType { STARTED , FINISHED, FAILED, PROGRESS_CHANGED, STATUS_CHANGED, OUTPUT_CHANGED }

public interface DownloaderData : Object
{
	public abstract string filename { get; set; default = null; }
	public abstract string filepath { get; set; default = null; }
	public abstract string downloader_path { get; set; default = null; }
	public abstract string download_path { get; set; default = null; }
	public abstract ArrayList<string> arguments { get; set; }
	public abstract string link { get; set; default = null; }
	public abstract bool replace { get; set; default = false; }

	public abstract void initialize_arguments();	
}

public interface Downloader : Object
{
	public abstract signal void started();
	public abstract signal void finished();
	public abstract signal void failed(string error_message);
	public abstract signal void progress_changed( int percent , string? transfer_rate = null);
	public abstract signal void status_changed();
	public abstract signal void output_changed(string output);

	public abstract int progress { get; }
	public abstract string transfer_rate { get; }
	public abstract string size { get; }
	public abstract string output { get; }
	public abstract string error_message { get; }	

	public abstract void start();
	public abstract void stop();
}

public class DownloadManager : GLib.Object {

	Downloader _downloader;
    ArrayList<DownloaderData> _data_list = new ArrayList<DownloaderData>();
	string _download_directory = "";
	bool _stop_flag = false;

	//Manager
	BaseManager _base_mgr;

	Package[] _packages;
	Source[] _sources;

	public signal void item_status_changed ( int index, DownloadStatusType status_type, Downloader dl );

	//Properties
	public Package[] packages { get { return _packages; } }
	public Source[] sources { get { return _sources; } }

	public DownloadManager.from_packages(Package[] packages, string download_directory, BaseManager base_mgr)
	{		
		_packages = packages;
		_download_directory = download_directory;
		_base_mgr = base_mgr;
		
		foreach ( Package p in _packages )
		{
			//Axel Downloader
			DownloaderData data = create_init_downloader_data();			
			
			data.filename = File.new_for_path(p.filename).get_basename();
			data.link = p.filename;
			data.download_path = _download_directory;			
			_data_list.add(data);
		}
	}

	public DownloadManager.from_sources(Source[] sources, string download_directory, BaseManager base_mgr)
	{
		_sources = sources;
		_download_directory = download_directory;
		_base_mgr = base_mgr;
		
		foreach ( Source s in _sources )
		{
			if ( s.link == null )
				continue;
			DownloaderData data = create_init_downloader_data();
			data.filename = s.filename + ".gz";
			data.link = s.link;
			data.download_path = _download_directory;
			data.replace = true;
			_data_list.add(data);
		}
	}

	public void start()
	{
		for ( int ctr = 0; ctr< _data_list.size; ctr++)
		{
			//Check if triggered to stop
			if ( _stop_flag )
			{
				_stop_flag = false;
				return;
			}
			
			_downloader = create_init_downloader( _data_list[ctr] );
			
			_downloader.started.connect( ()=> {				
				item_status_changed(ctr,DownloadStatusType.STARTED,_downloader);
			});
			_downloader.finished.connect( ()=> {				
				item_status_changed(ctr,DownloadStatusType.FINISHED,_downloader);
			});
			_downloader.failed.connect( ()=> {				
				item_status_changed(ctr,DownloadStatusType.FAILED,_downloader);
			});
			_downloader.status_changed.connect( ()=> {				
				item_status_changed(ctr,DownloadStatusType.STATUS_CHANGED,_downloader);
			});
			_downloader.progress_changed.connect( ()=> {
				item_status_changed(ctr,DownloadStatusType.PROGRESS_CHANGED,_downloader);
			});				

			_downloader.start();
			Thread.usleep(500000);
		}
	}

	public void stop()
	{
		_stop_flag = true;
		if ( _downloader != null )
			_downloader.stop();		
	}

	public DownloaderData create_init_downloader_data()
	{		
		DownloaderData data = new AxelData();
		ArrayList<string> argument_list = null;

		//Axel downloader
		if ( _base_mgr.main_configuration_file.get_value("default-downloader") == "axel" )
		{
			data = new AxelData();			
			data.downloader_path = Which.which ("axel",_base_mgr);

			string arguments = _base_mgr.main_configuration_file.get_value("axel-downloader-parameters");
			if ( arguments != null )
			{
				argument_list = new ArrayList<string>();
				foreach( string s in arguments.split(" ",-1) )
					argument_list.add(s);				
				
				data.arguments = argument_list;
			}		
			
			return data;
		}
		//Aria2 downloader
		else if ( _base_mgr.main_configuration_file.get_value("default-downloader") == "aria2c" )
		{
			data = new Aria2cData();			
			data.downloader_path = Which.which ("aria2c",_base_mgr);	

			string arguments = _base_mgr.main_configuration_file.get_value("aria2c-downloader-parameters");
			if ( arguments != null )
			{
				argument_list = new ArrayList<string>();
				foreach( string s in arguments.split(" ",-1) )
					argument_list.add(s);
				
				data.arguments = argument_list;
			}	
			
			return data;
		}
		
		return data;
	}

	public Downloader create_init_downloader(DownloaderData data)
	{
		if ( _base_mgr.main_configuration_file.get_value("default-downloader") == "axel" )
		{
			return new AxelDownloader(data);
		}
		else if ( _base_mgr.main_configuration_file.get_value("default-downloader") == "aria2c" )
		{
			return new Aria2cDownloader(data);
		}
		return new AxelDownloader(data);
	}
}