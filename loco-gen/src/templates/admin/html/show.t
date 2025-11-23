to: assets/views/admin/{{module_name}}/show.html
skip_exists: true
message: "Admin show view for {{module_name}} was added successfully."
---
{% raw %}{% extends "admin/base.html" %}{% endraw %}

{% raw %}{% block title %}{{display_name}} Details{% endblock title %}{% endraw %}

{% raw %}{% block content %}{% endraw %}
<div class="mb-4">
  <h1 class="text-2xl font-bold mb-4">{{display_name}} Details</h1>
  
  <div class="bg-white rounded shadow p-6">
    <dl class="grid grid-cols-1 gap-4 sm:grid-cols-2">
      {% for column in columns -%}
      <div>
        <dt class="text-sm font-medium text-gray-500">{{column.name | capitalize}}</dt>
        <dd class="mt-1 text-sm text-gray-900">
          {% raw %}{{ item.{% endraw %}{{column.name}}{% raw %} | default(value="N/A") }}{% endraw %}
        </dd>
      </div>
      {% endfor -%}
    </dl>
    
    <div class="mt-6 flex gap-4">
      <a href="{{prefix}}/{{route_prefix}}/{% raw %}{{ item.id }}{% endraw %}/edit" 
         class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600">
        Edit
      </a>
      <a href="{{prefix}}/{{route_prefix}}/" 
         class="bg-gray-500 text-white px-4 py-2 rounded hover:bg-gray-600">
        Back to List
      </a>
      <a href="#" 
         onclick="confirmDelete(event, '{{prefix}}/{{route_prefix}}/{% raw %}{{ item.id }}{% endraw %}', '{{prefix}}/{{route_prefix}}')" 
         class="bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600">
        Delete
      </a>
    </div>
  </div>
</div>
{% raw %}{% endblock content %}{% endraw %}

