<?php

// Include humanitarianresponse profiler
!function_exists('humanitarianresponse_profiler') ? require_once('libraries/humanitarianresponse_profiler/humanitarianresponse_profiler.inc') : FALSE;

/**
 * Implement hook_install_tasks().
 */
function emergency_site_install_tasks($install_state) {
  $needs_translations = humanitarianresponse_profiler_needs_translations($install_state);

  return array(
    'humanitarianresponse_profiler_import_translations' => array(
      'display_name' => st('Set up translations'),
      'display' => $needs_translations,
      'run' => $needs_translations ? INSTALL_TASK_RUN_IF_NOT_COMPLETED : INSTALL_TASK_SKIP,
      'type' => 'batch',
    ),
    'emergency_site_import_vocabularies_batch' => array(
      'display_name' => st('Import vocabularies'),
      'display' => TRUE,
      'run' => INSTALL_TASK_RUN_IF_NOT_COMPLETED,
      'type' => 'batch',
    ),
    'humanitarianresponse_profiler_import_aliases' => array(
      'display_name' => st('Import URL aliases'),
      'display' => TRUE,
      'run' => INSTALL_TASK_RUN_IF_NOT_COMPLETED,
      'type' => 'batch',
    ),
    'emergency_site_import_menus_batch' => array(
      'display_name' => st('Import menus'),
      'display' => TRUE,
      'run' => INSTALL_TASK_RUN_IF_NOT_COMPLETED,
      'type' => 'batch',
    ),
    'emergency_site_import_default_content' => array(
      'display_name' => st('Import default content'),
      'display' => TRUE,
      'run' => INSTALL_TASK_RUN_IF_NOT_COMPLETED,
      'type' => 'batch',
    ),
  );
}

function emergency_site_import_vocabularies_batch() {
  $options = array(
    'field_formats' => array(
      'clusters' => 'name,field_cluster_prefix,field_cluster_image'
    )
  );
  return humanitarianresponse_profiler_import_vocabularies_batch($options);
}
  

/**
 * Implement hook_install_tasks_alter().
 *
 * Perform actions to set up the site for this profile.
 */
function emergency_site_install_tasks_alter(&$tasks, $install_state) {
  // Remove core steps for translation imports.
  unset($tasks['install_import_locales']);
  unset($tasks['install_import_locales_remaining']);
  $tasks['install_select_locale']['function'] = 'humanitarianresponse_profiler_locale_selection';
  $tasks['install_load_profile']['function'] = 'humanitarianresponse_profiler_install_load_profile';
}

/**
 * Import menus including cluster menu
 */
function emergency_site_import_menus_batch() {
  $root_path = realpath(drupal_get_path('module', 'node').'/../../');
  $import_dir =  $root_path . '/' . drupal_get_path('profile', drupal_get_profile()) . '/menus/';

  $filename = $import_dir . 'cluster.csv';
  $row = 1;
  if (($handle = fopen($filename, "r")) !== FALSE) {
    while (($data = fgetcsv($handle, 1000, ",")) !== FALSE) {
      $title = $data[0];
      $path = $data[1];
      $options = array(
        'menu_token_link_path' => $path,
        'menu_token_data' => array(
          'term' => array(
            'type' => 'term',
            'plugin' => 'term_context',
            'options' => '',
          )
        )
      );
      $item = array(
        'link_path' => '<front>',
        'link_title' => $title,
        'menu_name' => 'menu-cluster',
        'options' => $options,
      );
      menu_link_save($item);
    }
    fclose($handle);
  }
  return humanitarianresponse_profiler_import_menus_batch();
}

/**
 * Import default content
 */
function emergency_site_import_default_content() {
  global $base_url;
  // Check URL
  preg_match('@^(?:http://)?([^.]+)(.humanitarianresponse.info)@i',
    $base_url, $matches);
  if (!empty($matches)) {
    $country = $matches[1];
    $node_path = drupal_get_normal_path('visuals-data/cod-fod');
    $nid = str_replace('node/', '', $node_path);
    if (!empty($nid)) {
      $node = node_load($nid);
      $code = '<iframe width=988 height=500 scrolling="auto" marginheight="0" marginwidth="0" src="http://cod.humanitarianresponse.info/country-region/'.$country.'?iframe"></iframe>';
      $node->body[LANGUAGE_NONE][0]['value'] = $code;
      $node->body[LANGUAGE_NONE][0]['format'] = 'full_html';
      node_save($node);
    }
  }
}
