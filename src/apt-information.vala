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

public class AptInformation
{
	public static string sources_file { get { return "/etc/apt/sources.list"; } }
	public static string sources_directory { get { return "/etc/apt/sources.list.d/"; } }
	public static string lists_directory { get { return "/var/lib/apt/lists"; } }
	public static string status_file { get { return "/var/lib/dpkg/status"; } }
	public static string preferences_file { get { return "/etc/apt/preferences"; } }
	public static string preferences_directory { get { return "/etc/apt/preferences.d/"; } }
}