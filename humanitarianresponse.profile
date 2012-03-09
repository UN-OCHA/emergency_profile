<?php

define('HUMANITARIANRESPONSE_PROFILER_DEBUG', TRUE);

// Include humanitarianresponse profiler
!function_exists('humanitarianresponse_profiler') ? require_once('libraries/humanitarianresponse/humanitarianresponse.inc') : FALSE;

/**
 * Implement hook_install_tasks().
 */
function humanitarianresponse_install_tasks($install_state) {
  $needs_translations = humanitarianresponse_profiler_needs_translations($install_state);

  return array(
    'humanitarianresponse_profiler_import_translations' => array(
      'display_name' => st('Set up translations'),
      'display' => $needs_translations,
      'run' => $needs_translations ? INSTALL_TASK_RUN_IF_NOT_COMPLETED : INSTALL_TASK_SKIP,
      'type' => 'batch',
    ),
    'humanitarianresponse_import_vocabularies_batch' => array(
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
    'humanitarianresponse_import_menus_batch' => array(
      'display_name' => st('Import menus'),
      'display' => TRUE,
      'run' => INSTALL_TASK_RUN_IF_NOT_COMPLETED,
      'type' => 'batch',
    ),
  );
}

function humanitarianresponse_import_vocabularies_batch() {
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
function humanitarianresponse_install_tasks_alter(&$tasks, $install_state) {
  // Remove core steps for translation imports.
  unset($tasks['install_import_locales']);
  unset($tasks['install_import_locales_remaining']);
  $tasks['install_select_locale']['function'] = 'humanitarianresponse_profiler_locale_selection';
  $tasks['install_load_profile']['function'] = 'humanitarianresponse_profiler_install_load_profile';
}

/**
 * Import menus including cluster menu
 */
function humanitarianresponse_import_menus_batch() {
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
