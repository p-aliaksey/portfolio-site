# -*- coding: utf-8 -*-
"""
Система переводов для DevOps Portfolio
Поддерживает русский и английский языки
"""

from flask import request, session
import json
import os

class Translations:
    def __init__(self):
        self.translations = self._load_translations()
    
    def _load_translations(self):
        """Загружает переводы из JSON файлов"""
        translations = {}
        translations_dir = os.path.join(os.path.dirname(__file__), 'translations')
        
        for lang in ['ru', 'en']:
            file_path = os.path.join(translations_dir, f'{lang}.json')
            try:
                if os.path.exists(file_path):
                    with open(file_path, 'r', encoding='utf-8') as f:
                        translations[lang] = json.load(f)
                else:
                    print(f"Warning: Translation file {file_path} not found")
                    translations[lang] = {}
            except Exception as e:
                print(f"Error loading translation file {file_path}: {str(e)}")
                translations[lang] = {}
        
        return translations
    
    def get_language(self):
        """Определяет текущий язык"""
        # 1. Проверяем параметр в URL
        if request.args.get('lang'):
            return request.args.get('lang')
        
        # 2. Проверяем сессию
        if 'language' in session:
            lang = session['language']
            print(f"Language from session: {lang}")
            return lang
        
        # 3. Проверяем заголовок Accept-Language
        accept_language = request.headers.get('Accept-Language', '')
        if 'en' in accept_language.lower():
            return 'en'
        
        # 4. По умолчанию русский
        return 'ru'
    
    def set_language(self, lang):
        """Устанавливает язык в сессии"""
        try:
            if lang in self.translations:
                session['language'] = lang
                return True
            return False
        except Exception as e:
            print(f"Error setting language {lang}: {str(e)}")
            return False
    
    def translate(self, key, **kwargs):
        """Переводит ключ на текущий язык"""
        lang = self.get_language()
        translation = self.translations.get(lang, {}).get(key, key)
        
        # Заменяем плейсхолдеры
        if kwargs:
            try:
                translation = translation.format(**kwargs)
            except (KeyError, ValueError):
                pass
        
        return translation
    
    def get_all_translations(self):
        """Возвращает все переводы для текущего языка"""
        lang = self.get_language()
        translations = self.translations.get(lang, {})
        if not translations:
            print(f"Warning: No translations found for language: {lang}")
            print(f"Available languages: {list(self.translations.keys())}")
        return translations

# Глобальный экземпляр
translations = Translations()

def _(key, **kwargs):
    """Удобная функция для перевода"""
    return translations.translate(key, **kwargs)
