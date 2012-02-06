<?php

!function_exists('profiler_v2') ? require_once('libraries/profiler/profiler.inc') : FALSE;
profiler_v2('humanitarianresponse');

// Include grupal profiler
!function_exists('grupal_profiler') ? require_once('libraries/grupal/grupal.inc') : FALSE;

/**
 * Implement hook_install_tasks().
 */
function humanitarianresponse_install_tasks($install_state) {
  $needs_translations = grupal_profiler_needs_translations($install_state);

  return array(
    'grupal_profiler_import_translations' => array(
      'display_name' => st('Set up translations'),
      'display' => $needs_translations,
      'run' => $needs_translations ? INSTALL_TASK_RUN_IF_NOT_COMPLETED : INSTALL_TASK_SKIP,
      'type' => 'batch',
    ),
  );
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
  $tasks['install_select_locale']['function'] = 'grupal_profiler_locale_selection';
  $tasks['install_load_profile']['function'] = 'grupal_profiler_install_load_profile';
}

