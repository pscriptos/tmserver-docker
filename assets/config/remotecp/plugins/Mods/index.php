<?php
/**
* remoteCP 4
* ütf-8 release
*
* @package remoteCP
* @author hal.sascha
* @copyright (c) 2006-2009
* @version 4.0.2.6
*
* Patch: foreach()-Warnungen behoben – leere Umgebungen (Island, Bay, …)
*        fuehrten zu "Invalid argument supplied for foreach()", weil
*        $this->mods['Env'] nicht initialisiert war.
*        Zusaetzlich bare-constant-Warnungen (pt_*) mit defined()-Pruefungen entschaerft.
*/
class Mods extends rcp_plugin
{
	public  $display		= 'side';
	public  $title			= 'Mods';
	public  $author			= 'hal.ko.sascha';
	public  $version		= '4.0.3.5';
	public  $nservstatus	= array(2,3,4,5);
	public  $vpermissions	= array('editserversettings');
	public  $apermissions	= array(
		'setMods'	=> 'editserversettings',
		'setMusic'	=> 'editserversettings'
	);

	private $mods			= array();
	private $music			= array();

	/**
	 * Alle bekannten Umgebungs-Keys mit leeren Arrays vorbelegen,
	 * damit foreach() auch bei fehlenden Eintraegen nicht warnt.
	 */
	private function initModDefaults()
	{
		$envs = array('Stadium', 'Island', 'Bay', 'Coast', 'Speed', 'Alpine', 'Rally');
		foreach($envs as $env) {
			if(!isset($this->mods[$env])) {
				$this->mods[$env] = array();
			}
		}
	}

	public function onLoadSettings($settings)
	{
		// Set defaults
		$this->mods = array();
		$this->music = array();

		// Alle Umgebungen vorinitialisieren
		$this->initModDefaults();

		// Read mods settings
		if(!$settings->mods) return;
		foreach($settings->mods->children() AS $env)
		{
			if(!$env) continue;
			$tmp = (string) $env->getName();
			if(!isset($this->mods[$tmp])) {
				$this->mods[$tmp] = array();
			}
			foreach($env->children() AS $item)
			{
				$this->mods[$tmp][] = array(
					'url'	=> (string) $item,
					'name'	=> (string) $item['name']
				);
			}
		}

		// Read music settings
		if(!$settings->music) return;
		foreach($settings->music->children() AS $song)
		{
			$this->music[] = array(
				'url'	=> (string) $song,
				'name'	=> (string) $song['name']
			);
		}
	}

	public function onOutput() {
		if(Core::getObject('gbx')->query('GetForcedMods')) {
			$ForcedMods = Core::getObject('gbx')->getResponse();

			if(!empty($ForcedMods)) {
				echo "<fieldset>";
				echo "<div class='legend'>".(defined('pt_forcedmods') ? pt_forcedmods : 'Forced Mods')."</div>";
				if(is_array($ForcedMods['Mods'])) {
					foreach($ForcedMods['Mods'] as $mod)
					{
						echo "<div class='f-row'>
								<label>{$mod['Env']}</label>
								<div class='f-field'>". $this->getModName($mod['Env'], $mod['Url']) ."</div>";
						echo "</div>";
					}
				}
				echo "</fieldset>";
			}
		}

		echo "<form action='ajax.php' method='post' id='forcemods' name='forcemods' class='postcmd' rel='{$this->display}area'>";
		echo "<fieldset>";
		echo "<div class='legend'>".(defined('pt_forcemods') ? pt_forcemods : 'Force Mods')."</div>";

		// --- Stadium ---
		echo "	<div class='f-row'>
					<label for='points'>".(defined('pt_stadium') ? pt_stadium : 'Stadium')."</label>
					<div class='f-field'>
						<select name='modstadium'>";
						echo "<option value='0'>".(defined('pt_none') ? pt_none : 'None')."</option>";
						if(!empty($this->mods['Stadium'])) {
							foreach($this->mods['Stadium'] AS $mod)
							{
								echo "<option value='{$mod['url']}'>{$mod['name']}</option>";
							}
						}
		echo "			</select>
					</div>
				</div>";

		// --- Island ---
		echo "	<div class='f-row'>
					<label for='points'>".(defined('pt_island') ? pt_island : 'Island')."</label>
					<div class='f-field'>
						<select name='modisland'>";
						echo "<option value='0'>".(defined('pt_none') ? pt_none : 'None')."</option>";
						if(!empty($this->mods['Island'])) {
							foreach($this->mods['Island'] AS $mod)
							{
								echo "<option value='{$mod['url']}'>{$mod['name']}</option>";
							}
						}
		echo "			</select>
					</div>
				</div>";

		// --- Bay ---
		echo "<div class='f-row'>
					<label for='points'>".(defined('pt_bay') ? pt_bay : 'Bay')."</label>
					<div class='f-field'>
						<select name='modbay'>";
						echo "<option value='0'>".(defined('pt_none') ? pt_none : 'None')."</option>";
						if(!empty($this->mods['Bay'])) {
							foreach($this->mods['Bay'] AS $mod)
							{
								echo "<option value='{$mod['url']}'>{$mod['name']}</option>";
							}
						}
		echo "			</select>
					</div>
				</div>";

		// --- Coast ---
		echo "	<div class='f-row'>
					<label for='points'>".(defined('pt_coast') ? pt_coast : 'Coast')."</label>
					<div class='f-field'>
						<select name='modcoast'>";
						echo "<option value='0'>".(defined('pt_none') ? pt_none : 'None')."</option>";
						if(!empty($this->mods['Coast'])) {
							foreach($this->mods['Coast'] AS $mod)
							{
								echo "<option value='{$mod['url']}'>{$mod['name']}</option>";
							}
						}
		echo "			</select>
					</div>
				</div>";

		// --- Speed ---
		echo "	<div class='f-row'>
					<label for='points'>".(defined('pt_speed') ? pt_speed : 'Speed')."</label>
					<div class='f-field'>
						<select name='modspeed'>";
						echo "<option value='0'>".(defined('pt_none') ? pt_none : 'None')."</option>";
						if(!empty($this->mods['Speed'])) {
							foreach($this->mods['Speed'] AS $mod)
							{
								echo "<option value='{$mod['url']}'>{$mod['name']}</option>";
							}
						}
		echo "			</select>
					</div>
				</div>";

		// --- Alpine ---
		echo "	<div class='f-row'>
					<label for='points'>".(defined('pt_alpine') ? pt_alpine : 'Alpine')."</label>
					<div class='f-field'>
						<select name='modalpine'>";
						echo "<option value='0'>".(defined('pt_none') ? pt_none : 'None')."</option>";
						if(!empty($this->mods['Alpine'])) {
							foreach($this->mods['Alpine'] AS $mod)
							{
								echo "<option value='{$mod['url']}'>{$mod['name']}</option>";
							}
						}
		echo "			</select>
					</div>
				</div>";

		// --- Rally ---
		echo "	<div class='f-row'>
					<label for='points'>".(defined('pt_rally') ? pt_rally : 'Rally')."</label>
					<div class='f-field'>
						<select name='modrally'>";
						echo "<option value='0'>".(defined('pt_none') ? pt_none : 'None')."</option>";
						if(!empty($this->mods['Rally'])) {
							foreach($this->mods['Rally'] AS $mod)
							{
								echo "<option value='{$mod['url']}'>{$mod['name']}</option>";
							}
						}
		echo "			</select>
					</div>
				</div>";

		echo "	<div class='f-row'>
					<label for='DisableAllMods'>".(defined('pt_disableall') ? pt_disableall : 'Disable All')."</label>
					<div class='f-field'><input type='checkbox' class='checkbox' name='DisableAllMods' /></div>
				</div>";
		echo "</fieldset>";
		echo "<input type='hidden' name='plugin' value='{$this->id}' />";
		echo "<input type='hidden' name='action' value='setMods' />";
		echo "<button type='submit' title='".(defined('ct_submit') ? ct_submit : 'Submit')."' class='wide'>".(defined('ct_submit') ? ct_submit : 'Submit')."</button>";
		echo "</form>";

		if(Core::getObject('gbx')->query('GetForcedMusic')) {
			$ForcedMusic = Core::getObject('gbx')->getResponse();

			if(!empty($ForcedMusic)) {
				echo "<fieldset>";
				echo "<div class='legend'>".(defined('pt_forcedmusic') ? pt_forcedmusic : 'Forced Music')."</div>";
				echo "<div class='f-row'>
						<label>{$ForcedMusic['File']}</label>
						<div class='f-field'>{$ForcedMusic['Url']}</div>";
				echo "</div>";
				echo "</fieldset>";
			}
		}

		echo "<form action='ajax.php' method='post' id='forcemusic' name='forcemusic' class='postcmd' rel='{$this->display}area'>";
		echo "<fieldset>";
		echo "<div class='legend'>".(defined('pt_forcemusic') ? pt_forcemusic : 'Force Music')."</div>";
		echo "<div class='f-row'>
				<label for='song'>".(defined('pt_song') ? pt_song : 'Song')."</label>
				<div class='f-field'>
					<select name='song'>";
					if(!empty($this->music)) {
						foreach($this->music AS $song)
						{
							echo "<option value='{$song['url']}'>{$song['name']}</option>";
						}
					}
		echo "		</select>
				</div>";
		echo "	<div class='f-row'>
					<label for='DisableAllMusic'>".(defined('pt_disableall') ? pt_disableall : 'Disable All')."</label>
					<div class='f-field'><input type='checkbox' class='checkbox' name='DisableAllMusic' /></div>
				</div>";
		echo "</fieldset>";
		echo "<input type='hidden' name='plugin' value='{$this->id}' />";
		echo "<input type='hidden' name='action' value='setMusic' />";
		echo "<button type='submit' title='".(defined('ct_submit') ? ct_submit : 'Submit')."' class='wide'>".(defined('ct_submit') ? ct_submit : 'Submit')."</button>";
		echo "</form>";
	}

	public function setMods()
	{
		$array = array();
		$override = true;
		if(!array_key_exists('DisableAllMods', $_REQUEST)) {
			if(!empty($_REQUEST['modstadium']))
				$array[] = array('Env' => 'Stadium', 'Url' => $_REQUEST['modstadium']);
			if(!empty($_REQUEST['modisland']))
				$array[] = array('Env' => 'Island'	, 'Url' => $_REQUEST['modisland']);
			if(!empty($_REQUEST['modbay']))
				$array[] = array('Env' => 'Bay' , 'Url' => $_REQUEST['modbay']);
			if(!empty($_REQUEST['modcoast']))
				$array[] = array('Env' => 'Coast'	, 'Url' => $_REQUEST['modcoast']);
			if(!empty($_REQUEST['modspeed']))
				$array[] = array('Env' => 'Speed'	, 'Url' => $_REQUEST['modspeed']);
			if(!empty($_REQUEST['modalpine']))
				$array[] = array('Env' => 'Alpine'	, 'Url' => $_REQUEST['modalpine']);
			if(!empty($_REQUEST['modrally']))
				$array[] = array('Env' => 'Rally'	, 'Url' => $_REQUEST['modrally']);
		} else {
			$override = false;
		}
		Core::getObject('actions')->add('SetForcedMods', $override, $array);
	}

	public function setMusic()
	{
		$url = '';
		$override = true;
		if(!array_key_exists('DisableAllMusic', $_REQUEST)) {
			$url = $_REQUEST['song'];
		} else {
			$override = false;
		}
		Core::getObject('actions')->add('SetForcedMusic', $override, $url);
	}

	private function getModName($env, $url)
	{
		if(!isset($this->mods[$env]) || !is_array($this->mods[$env])) {
			return '';
		}
		foreach($this->mods[$env] AS $value)
		{
			if($url == $value['url']) {
				return $value['name'];
			}
		}
		return '';
	}
}
