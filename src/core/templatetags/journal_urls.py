"""
Custom template tags for generating journal-specific URLs with path-based routing.
"""
from django import template
from django.urls import reverse
from django.conf import settings

register = template.Library()


@register.simple_tag(takes_context=True)
def journal_url(context, view_name, *args, **kwargs):
    """
    Generate a URL for a view, including the journal code prefix for path-based routing.
    
    Usage: {% journal_url 'article_download_galley' article.id galley.id %}
    """
    url = reverse(view_name, args=args, kwargs=kwargs)
    
    # For path-based routing, prepend the journal code
    if settings.URL_CONFIG == "path" and hasattr(context['request'], 'journal') and context['request'].journal:
        journal_code = context['request'].journal.code
        url = f"/{journal_code}{url}"
    
    return url
