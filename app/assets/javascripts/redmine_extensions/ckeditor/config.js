/**
 * @license Copyright (c) 2003-2014, CKSource - Frederico Knabben. All rights reserved.
 * For licensing, see LICENSE.md or http://ckeditor.com/license
 */

CKEDITOR.editorConfig = function( config )
{
    // Define changes to default configuration here. For example:
    // config.language = 'fr';
    // config.uiColor = '#AADC6E';

    config.removePlugins = 'scayt';
    config.extraPlugins = 'base64image';
    config.entities_latin = false;
    config.disableNativeSpellChecker = true;
    config.skin = 'moono';
    config.resize_enabled = true;
    config.toolbarStartupExpanded = true;
    config.toolbarCanCollapse = false;
    config.extraAllowedContent = 'blockquote table pre code big small img section a i span div; *[id](*){*}; *[class](*){*}; *[style](*){*}; *[data*](*){*}';
    config.keystrokes = [];
    config.keystrokes = [
        [ CKEDITOR.CTRL + 76, null ],                       // CTRL + L
    ];
    // config.allowedContent = true;
    config.tabSpaces = 4;
    config.contentsCss = ['/plugin_assets/easy_extensions/stylesheets/basic.css', '/plugin_assets/easy_extensions/stylesheets/easy_icons.css'];
    config.toolbar_Full = [
    ['Bold','Italic','Underline','Strike','NumberedList','BulletedList','Subscript','Superscript','-','Outdent','Indent','Blockquote'],
    ['Styles','Format','Font','FontSize'],
    ['TextColor','BGColor'],
    ['JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock'],
    ['Link','Unlink','Anchor'],
    ['base64image','Table','HorizontalRule','Smiley','SpecialChar','-','Maximize', 'ShowBlocks'],
    ['Cut','Copy','Paste','PasteText','PasteFromWord','-','Print', 'SpellChecker'],
    ['Undo','Redo','-','Find','Replace','-','SelectAll','RemoveFormat'],
    ['Source','Preview','Templates', 'CodeSnippet']
    ];

    config.toolbar_Extended = [
    ['Bold','Italic','Underline','Strike'],['TextColor','BGColor','Link','Unlink'],
    ['NumberedList','BulletedList'],['base64image','PasteFromWord','Table','Source'],
    ['JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock'],
    ['Format','Font','FontSize'],
    ['Table','HorizontalRule'],
    ['Cut','Copy','Paste','PasteText']
    ];

    config.toolbar_Basic = [
    ['Bold','Italic','Underline','Strike'],['TextColor','BGColor','Link','Unlink'],
    ['NumberedList','BulletedList'],['base64image','PasteFromWord','Table','Source']
    ];

    config.toolbar_Publishing = [
    ['Bold','Italic','Underline','Strike'],['TextColor','BGColor','Link','Unlink'],
    ['NumberedList','BulletedList'],['base64image','PasteFromWord','Table','Source']
    ];
};
