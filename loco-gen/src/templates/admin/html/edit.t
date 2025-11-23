to: assets/views/admin/{{module_name}}/edit.html
skip_exists: true
message: "Admin edit form for {{module_name}} was added successfully."
---
{% raw %}{% extends "admin/base.html" %}{% endraw %}

{% raw %}{% block title %}Edit {{display_name}}{% endblock title %}{% endraw %}

{% raw %}{% block content %}{% endraw %}
<div class="mb-4">
  <h1 class="text-2xl font-bold mb-4">Edit {{display_name}}</h1>
  
  <form hx-ext="submitjson" 
        hx-put="{{prefix}}/{{route_prefix}}/{% raw %}{{ item.id }}{% endraw %}"
        hx-target="body"
        class="bg-white rounded shadow p-6">
    {% for field in form_fields -%}
    <div class="mb-4">
      <label for="{{field.name}}" class="block text-sm font-medium text-gray-700 mb-1">
        {{field.name | capitalize}}{% if field.required %} *{% endif %}
      </label>
      {% if field.is_foreign_key -%}
      <select name="{{field.name}}" id="{{field.name}}" 
              class="border rounded px-3 py-2 w-full"{% if field.required %} required{% endif %}>
        <option value="">-- Select {{field.related_entity | capitalize}} --</option>
        {% raw %}{% for rel_item in {% endraw %}{{field.related_module}}_items{% raw %} %}{% endraw %}
        <option value="{% raw %}{{ rel_item.id }}{% endraw %}" 
                {% raw %}{% if item.{% endraw %}{{field.name}}{% raw %} == Some(rel_item.id) or item.{% endraw %}{{field.name}}{% raw %} == rel_item.id %}{% endraw %}selected{% raw %}{% endif %}{% endraw %}>
          {% raw %}{{ rel_item.name | default(value=rel_item.email) | default(value=rel_item.id) }}{% endraw %}
        </option>
        {% raw %}{% endfor %}{% endraw %}
      </select>
      {%- elif field.input_type == "textarea" -%}
      <textarea name="{{field.name}}" id="{{field.name}}" 
                class="border rounded px-3 py-2 w-full"{% if field.required %} required{% endif %}>{% raw %}{{ item.{% endraw %}{{field.name}}{% raw %} | default(value="") }}{% endraw %}</textarea>
      {%- elif field.input_type == "checkbox" -%}
      <input type="checkbox" name="{{field.name}}" id="{{field.name}}" 
             class="border rounded"{% raw %}{% if item.{% endraw %}{{field.name}}{% raw %} %}{% endraw %} checked{% raw %}{% endif %}{% endraw %}>
      {%- else -%}
      <input type="{{field.input_type}}" name="{{field.name}}" id="{{field.name}}" 
             value="{% raw %}{{ item.{% endraw %}{{field.name}}{% raw %} | default(value="") }}{% endraw %}"
             class="border rounded px-3 py-2 w-full"{% if field.required %} required{% endif %}>
      {%- endif %}
    </div>
    {% endfor -%}
    
    <div class="flex gap-4">
      <button type="submit" class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600">
        Update
      </button>
      <a href="{{prefix}}/{{route_prefix}}/" class="bg-gray-500 text-white px-4 py-2 rounded hover:bg-gray-600">
        Cancel
      </a>
    </div>
  </form>
</div>
{% raw %}{% endblock content %}{% endraw %}

