<?php

!function_exists('profiler_v2') ? require_once('libraries/profiler/profiler.inc') : FALSE;
profiler_v2('humanitarianresponse');

/**
 * Implement hook_install_tasks().
 */
function humanitarianresponse_install_tasks($install_state) {
  // Determine whether translation import tasks will need to be performed.
  $needs_translations = FALSE;
  if (!empty($install_state['parameters']['locale'])) {
    /*if (!$install_state['interactive']) {
      // Try to get additional locales from drush
      $install_state['parameters']['additional_locales'] = humanitarianresponse_clean_additional_locales(drush_get_option('extra_languages', array()), $install_state['parameters']['locale']);
    }*/
    if (!empty($install_state['parameters']['additional_locales'])) {
      $needs_translations = TRUE;
    }
    else {
      $needs_translations = count($install_state['locales']) > 1 && $install_state['parameters']['locale'] != 'en';
    }
  }

  return array(
    'humanitarianresponse_import_translation' => array(
      'display_name' => st('Set up translations'),
      'display' => $needs_translations,
      'run' => $needs_translations ? INSTALL_TASK_RUN_IF_NOT_COMPLETED : INSTALL_TASK_SKIP,
      'type' => 'batch',
    ),
  );
}

function humanitarianresponse_clean_additional_locales($additional_locales, $locale) {
  // Remove main language from additional locales
  if (isset($additional_locales[$locale])) {
    unset($additional_locales[$locale]);
  }
  return $additional_locales;
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
  $tasks['install_select_locale']['function'] = 'humanitarianresponse_locale_selection';
  $tasks['install_load_profile']['function'] = 'humanitarianresponse_install_load_profile';
}

function humanitarianresponse_locale_selection(&$install_state) {
  // Find all available locales.
  $profilename = $install_state['parameters']['profile'];
  $locales = install_find_locales($profilename);
  $install_state['locales'] += $locales;

  if (!empty($_POST['locale'])) {
    foreach ($locales as $locale) {
      if ($_POST['locale'] == $locale->langcode) {
        $install_state['parameters']['locale'] = $locale->langcode;
      }
    }

    if (!empty($_POST['additional_locales'])) {
      $additional_locales = humanitarianresponse_clean_additional_locales(array_keys($_POST['additional_locales']), $install_state['parameters']['locale']);
      foreach ($locales as $locale) {
        if (in_array($locale->langcode, $additional_locales) && !in_array($locale->langcode, $install_state['parameters']['additional_locales'])) {
          $install_state['parameters']['additional_locales'][] = $locale->langcode;
        }
      }
    }
    
    return;
  }

  if (empty($install_state['parameters']['locale'])) {
    // If only the built-in (English) language is available, and we are
    // performing an interactive installation, inform the user that the
    // installer can be localized. Otherwise we assume the user knows what he
    // is doing.
    if (count($locales) == 1) {
      if ($install_state['interactive']) {
        drupal_set_title(st('Choose language'));
        if (!empty($install_state['parameters']['localize'])) {
          $output = '<p>Follow these steps to translate Drupal into your language:</p>';
          $output .= '<ol>';
          $output .= '<li>Download a translation from the <a href="http://localize.drupal.org/download" target="_blank">translation server</a>.</li>';
          $output .= '<li>Place it into the following directory:
<pre>
/profiles/' . $profilename . '/translations/
</pre></li>';
          $output .= '</ol>';
          $output .= '<p>For more information on installing Drupal in different languages, visit the <a href="http://drupal.org/localize" target="_blank">drupal.org handbook page</a>.</p>';
          $output .= '<p>How should the installation continue?</p>';
          $output .= '<ul>';
          $output .= '<li><a href="install.php?profile=' . $profilename . '">Reload the language selection page after adding translations</a></li>';
          $output .= '<li><a href="install.php?profile=' . $profilename . '&amp;locale=en">Continue installation in English</a></li>';
          $output .= '</ul>';
        }
        else {
          include_once DRUPAL_ROOT . '/includes/form.inc';
          $elements = drupal_get_form('install_select_locale_form', $locales, $profilename);
          $output = drupal_render($elements);
        }
        return $output;
      }
      // One language, but not an interactive installation. Assume the user
      // knows what he is doing.
      $locale = current($locales);
      $install_state['parameters']['locale'] = $locale->name;
      return;
    }
    else {
      // Allow profile to pre-select the language, skipping the selection.
      $function = $profilename . '_profile_details';
      if (function_exists($function)) {
        $details = $function();
        if (isset($details['language'])) {
          foreach ($locales as $locale) {
            if ($details['language'] == $locale->name) {
              $install_state['parameters']['locale'] = $locale->name;
              return;
            }
          }
        }
      }

      // We still don't have a locale, so display a form for selecting one.
      // Only do this in the case of interactive installations, since this is
      // not a real form with submit handlers (the database isn't even set up
      // yet), rather just a convenience method for setting parameters in the
      // URL.
      if ($install_state['interactive']) {
        drupal_set_title(st('Choose language'));
        include_once DRUPAL_ROOT . '/includes/form.inc';
        $elements = drupal_get_form('humanitarianresponse_install_select_locale_form', $locales, $profilename);
        return drupal_render($elements);
      }
      else {
        throw new Exception(st('Sorry, you must select a language to continue the installation.'));
      }
    }
  }
  
  if (empty($install_state['parameters']['additional_locales'])) {
    $install_state['parameters']['additional_locales'] = humanitarianresponse_clean_additional_locales(drush_get_option('extra_languages', array()), $install_state['parameters']['locale']);
  }
}

/**
 * Form API array definition for language selection.
 */
function humanitarianresponse_install_select_locale_form($form, &$form_state, $locales, $profilename) {
  include_once DRUPAL_ROOT . '/includes/iso.inc';
  $languages = _locale_get_predefined_list();
  $form['locale_text'] = array(
    '#markup' => st('Select the main language for your site'),
  );
  $locale_list = array();
  foreach ($locales as $locale) {
    $name = $locale->langcode;
    if (isset($languages[$name])) {
      $name = $languages[$name][0] . (isset($languages[$name][1]) ? ' ' . st('(@language)', array('@language' => $languages[$name][1])) : '');
    }
    $langcode = $locale->langcode;
    $locale_list[$langcode] = $name . ($locale->langcode == 'en' ? ' ' . st('(built-in)') : '');
    $form['locale'][$locale->langcode] = array(
      '#type' => 'radio',
      '#return_value' => $locale->langcode,
      '#default_value' => $locale->langcode == 'en' ? 'en' : '',
      '#title' => $name . ($locale->langcode == 'en' ? ' ' . st('(built-in)') : ''),
      '#parents' => array('locale')
    );
  }
  if (count($locales) == 1) {
    $form['help'] = array(
      '#markup' => '<p><a href="install.php?profile=' . $profilename . '&amp;localize=true">' . st('Learn how to install Drupal in other languages') . '</a></p>',
    );
  }
  else {
    $form['additional_locales'] = array(
      '#type' => 'checkboxes',
      '#options' => $locale_list,
      '#title' => st('Check additional languages to be installed on your site')
    );
  }
  $form['actions'] = array('#type' => 'actions');
  $form['actions']['submit'] =  array(
    '#type' => 'submit',
    '#value' => st('Save and continue'),
  );
  return $form;
}

function humanitarianresponse_install_load_profile(&$install_state) {
  install_load_profile($install_state);
  // Add grupal_i18n to the list of dependencies
  if (!empty($install_state['profile_info']['dependencies']) && !in_array('grupal_i18n', $install_state['profile_info']['dependencies']) && !empty($install_state['parameters']['additional_locales'])) {
    $install_state['profile_info']['dependencies'][] = 'grupal_i18n';
  }
}

/**
 * Installation step callback.
 *
 * @param $install_state
 *   An array of information about the current installation state.
 */
function humanitarianresponse_import_translation(&$install_state) {
  // Enable installation language as default site language.
  include_once DRUPAL_ROOT . '/includes/locale.inc';
  $install_locale = $install_state['parameters']['locale'];
  if ($install_locale != 'en') {
    locale_add_language($install_locale, NULL, NULL, NULL, '', NULL, 1, TRUE);
  }
  $additional_locales = $install_state['parameters']['additional_locales'];
  foreach ($additional_locales as $locale) {
    locale_add_language($locale, NULL, NULL, NULL, '', NULL, 1, FALSE);
  }
  
  variable_set('l10n_update_check_mode', L10N_UPDATE_CHECK_LOCAL);

  // Build batch with l10n_update module.
  $history = l10n_update_get_history();
  module_load_include('check.inc', 'l10n_update');
  $available = l10n_update_available_releases();
  $updates = l10n_update_build_updates($history, $available);

  module_load_include('batch.inc', 'l10n_update');
  $updates = _l10n_update_prepare_updates($updates, NULL, array());
  $batch = l10n_update_batch_multiple($updates, LOCALE_IMPORT_KEEP);
  return $batch;
}
