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
            if os.path.exists(file_path):
                with open(file_path, 'r', encoding='utf-8') as f:
                    translations[lang] = json.load(f)
        
        return translations
    
    def get_language(self):
        """Определяет текущий язык"""
        # 1. Проверяем параметр в URL
        if request.args.get('lang'):
            return request.args.get('lang')
        
        # 2. Проверяем сессию
        if 'language' in session:
            return session['language']
        
        # 3. Проверяем заголовок Accept-Language
        accept_language = request.headers.get('Accept-Language', '')
        if 'en' in accept_language.lower():
            return 'en'
        
        # 4. По умолчанию русский
        return 'ru'
    
    def set_language(self, lang):
        """Устанавливает язык в сессии"""
        if lang in self.translations:
            session['language'] = lang
    
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
        return self.translations.get(lang, {})

# Глобальный экземпляр
translations = Translations()

def _(key, **kwargs):
    """Удобная функция для перевода"""
    return translations.translate(key, **kwargs)
