to: assets/views/admin/{{module_name}}/list.html
skip_exists: true
message: "Admin list view for {{module_name}} was added successfully."
---
{% raw %}{% extends "admin/base.html" %}{% endraw %}

{% raw %}{% block title %}List {{display_name}}{% endblock title %}{% endraw %}

{% raw %}{% block content %}{% endraw %}
<div class="mb-4">
  <h1 class="text-2xl font-bold mb-4">{{display_name}}</h1>
  
  <div class="mb-4 flex gap-4">
    <form method="get" class="flex-1">
      <input type="text" name="search" placeholder="Search..." 
             value="{% raw %}{{ search | default(value="") }}{% endraw %}"
             class="border rounded px-3 py-2 w-full">
    </form>
    <a href="{{prefix}}/{{route_prefix}}/new" 
       class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600">
      Create New
    </a>
  </div>
  
  {% raw %}{% if items %}{% endraw %}
  <div class="bg-white rounded shadow overflow-hidden">
    <table class="min-w-full divide-y divide-gray-200">
      <thead class="bg-gray-50">
        <tr>
          {% for column in columns -%}
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
            {{column.name | capitalize}}
          </th>
          {% endfor -%}
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
            Actions
          </th>
        </tr>
      </thead>
      <tbody class="bg-white divide-y divide-gray-200">
        {% raw %}{% for item in items %}{% endraw %}
        <tr class="hover:bg-gray-50">
          {% for column in columns -%}
          <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
            {% raw %}{{ item.{% endraw %}{{column.name}}{% raw %} | escape }}{% endraw %}
          </td>
          {% endfor -%}
          <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
            <a href="{{prefix}}/{{route_prefix}}/{% raw %}{{ item.id }}{% endraw %}" class="text-blue-600 hover:text-blue-900 mr-2">View</a>
            <a href="{{prefix}}/{{route_prefix}}/{% raw %}{{ item.id }}{% endraw %}/edit" class="text-indigo-600 hover:text-indigo-900 mr-2">Edit</a>
            <a href="#" onclick="confirmDelete(event, '{{prefix}}/{{route_prefix}}/{% raw %}{{ item.id }}{% endraw %}', '{{prefix}}/{{route_prefix}}')" class="text-red-600 hover:text-red-900">Delete</a>
          </td>
        </tr>
        {% raw %}{% endfor %}{% endraw %}
      </tbody>
    </table>
  </div>
  
  {% raw %}{% if total_pages > 1 %}{% endraw %}
  <div class="mt-4 flex justify-center">
    {% raw %}{% if page > 1 %}{% endraw %}
    <a href="?page={% raw %}{{ page - 1 }}{% endraw %}" class="px-3 py-2 border rounded mr-2">Previous</a>
    {% raw %}{% endif %}{% endraw %}
    <span class="px-3 py-2">Page {% raw %}{{ page }}{% endraw %} of {% raw %}{{ total_pages }}{% endraw %}</span>
    {% raw %}{% if page < total_pages %}{% endraw %}
    <a href="?page={% raw %}{{ page + 1 }}{% endraw %}" class="px-3 py-2 border rounded ml-2">Next</a>
    {% raw %}{% endif %}{% endraw %}
  </div>
  {% raw %}{% endif %}{% endraw %}
  
  {% raw %}{% else %}{% endraw %}
  <div class="bg-white rounded shadow p-8 text-center">
    <p class="text-gray-500 mb-4">No items found.</p>
    <a href="{{prefix}}/{{route_prefix}}/new" 
       class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600">
      Create First Item
    </a>
  </div>
  {% raw %}{% endif %}{% endraw %}
</div>
{% raw %}{% endblock content %}{% endraw %}

