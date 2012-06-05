<?php

// Include humanitarianresponse profiler
!function_exists('humanitarianresponse_profiler') ? require_once('libraries/humanitarianresponse_profiler/humanitarianresponse_profiler.inc') : FALSE;

/**
 * Implement hook_install_tasks().
 */
function emergency_site_install_tasks($install_state) {

  return array(
    'emergency_site_import_menus_batch' => array(
      'display_name' => st('Import menu'),
      'display' => TRUE,
      'run' => INSTALL_TASK_RUN_IF_NOT_COMPLETED,
      'type' => 'batch'
    ),
    'emergency_site_rebuild_menus' => array(
      'display_name' => st('Rebuild menus'),
      'display' => TRUE,
      'run' => INSTALL_TASK_RUN_IF_NOT_COMPLETED,
      'type' => 'batch',
    ),
  );
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

function emergency_site_rebuild_menus(&$install_state) {
  drupal_flush_all_caches();
  features_revert(array('humanitarianresponse_emergency_menu'));
  $root_path = realpath(drupal_get_path('module', 'node').'/../../');

  $module_dir = $root_path . '/' . drupal_get_path('module', 'taxonomy_menu');
  require_once("$module_dir/taxonomy_menu.batch.inc");
  
  $voc_names = array('clusters', 'funding');
  $operations = array();
  
  foreach ($voc_names as $voc_name) {
    $voc = taxonomy_vocabulary_machine_name_load($voc_name);
    $vid = $voc->vid;
    $terms = taxonomy_get_tree($vid);
    $menu_name = variable_get(_taxonomy_menu_build_variable('vocab_menu', $vid), FALSE);
    $operations[] = array('_taxonomy_menu_insert_link_items_process', array($terms, $menu_name));
  }

  $batch = array(
    'operations' => $operations,
    'finished' => '_taxonomy_menu_insert_link_items_success',
    'title' => t('Rebuilding Taxonomy Menu'),
    'init_message' => t('The menu items have been deleted, and are about to be regenerated.'),
    'progress_message' => t('Import progress: Completed @current of @total stages.'),
    'error_message' => t('The Taxonomy Menu rebuild process encountered an error.'),
  );
  return $batch;
}
