<?php
/**
* remoteCP 4
* ütf-8 release
*
* @package remoteCP
* @author hal.sascha
* @copyright (c) 2006-2009
* @version 4.0.3.5
*
* Patched by tmserver-docker:
* - Bare-constant-Zugriffe (pt_custom, pt_points, ...) durch
*   defined()-Pruefungen ersetzt, um PHP 7.2+ Warnungen zu vermeiden.
*/
class CustomPoints extends rcp_plugin
{
    public $display        = 'side';
    public $title          = 'Points';
    public $author         = 'hal.ko.sascha';
    public $version        = '4.0.3.5';
    public $nservstatus    = array(2,3,4,5);
    public $vpermissions   = array('editgamesettings');
    public $apermissions   = array(
        'setPoints'         => 'editgamesettings',
        'setPointsPreset'   => 'editgamesettings'
    );
    public $presets;

    public function onLoad()
    {
        $this->presets = Core::getObject('session')->loadXML(
            Core::getSetting('pluginpath') . $this->id . '/presets.xml'
        );
    }

    public function onOutput()
    {
        $CustomPoints = array();

        if (Core::getObject('gbx')->query('GetRoundCustomPoints')) {
            $CustomPoints = Core::getObject('gbx')->getResponse();
        }

        if (!is_array($CustomPoints)) {
            $CustomPoints = array();
        }

        if (!Core::getObject('session')->checkPerm('editgamesettings')) {
            return;
        }

        echo "<form action='ajax.php' method='post' id='custompoints' name='custompoints' class='postcmd' rel='{$this->display}area'>";
        echo "<fieldset>";

        echo "<div class='legend'>" . (defined('pt_custom') ? pt_custom : 'Custom Points') . "</div>";

        echo "<div class='f-row'>
                <label for='points'>" . (defined('pt_points') ? pt_points : 'Points') . "</label>
                <div class='f-field'>
                    <input type='text' name='points' id='points' value='" . implode(',', $CustomPoints) . "' />
                    <div class='small'>" . (defined('pt_commasep') ? pt_commasep : 'Comma separated') . "</div>
                </div>";
        echo "</div>";

        echo "</fieldset>";

        echo "<input type='hidden' name='plugin' value='{$this->id}' />";
        echo "<input type='hidden' name='action' value='setPoints' />";
        echo "<button type='submit' title='" . (defined('ct_submit') ? ct_submit : 'Submit') . "' class='wide'>" . (defined('ct_submit') ? ct_submit : 'Submit') . "</button>";
        echo "</form>";

        echo "<form action='ajax.php' method='post' id='custompointspreset' name='custompointspreset' class='postcmd' rel='{$this->display}area'>";
        echo "<fieldset>";

        echo "<div class='legend'>" . (defined('pt_presets') ? pt_presets : 'Presets') . "</div>";

        if ($this->presets && is_object($this->presets)) {
            foreach ($this->presets->children() as $preset) {

                $name   = isset($preset['name'])   ? $preset['name']           : 'Preset';
                $points = isset($preset['points']) ? (string)$preset['points'] : '';

                echo "<div class='f-row'>
                        <label>{$name}</label>
                        <div class='f-field'>";

                echo "<input style='width:25px;' type='radio' name='preset' value='{$points}' /> ";

                if (strlen($points) > 25) {
                    echo substr($points, 0, 25) . "...";
                } else {
                    echo $points;
                }

                echo "</div>";
                echo "</div>";
            }
        }

        echo "</fieldset>";

        echo "<input type='hidden' name='plugin' value='{$this->id}' />";
        echo "<input type='hidden' name='action' value='setPointsPreset' />";
        echo "<button type='submit' title='" . (defined('ct_submit') ? ct_submit : 'Submit') . "' class='wide'>" . (defined('ct_submit') ? ct_submit : 'Submit') . "</button>";
        echo "</form>";
    }

    public function setPoints()
    {
        if (!array_key_exists('points', $_REQUEST)) return;

        $str   = preg_replace("/[^0-9,]/", "", $_REQUEST['points']);
        $array = $this->makeIntArray(explode(',', $str));

        Core::getObject('actions')->add('SetRoundCustomPoints', $array, true);
    }

    public function setPointsPreset()
    {
        if (!array_key_exists('preset', $_REQUEST)) return;

        $str   = preg_replace("/[^0-9,]/", "", $_REQUEST['preset']);
        $array = $this->makeIntArray(explode(',', $str));

        Core::getObject('actions')->add('SetRoundCustomPoints', $array, true);
    }

    private function makeIntArray($array)
    {
        foreach ($array as $key => $value) {
            $array[$key] = (int)$value;
        }
        return $array;
    }
}
