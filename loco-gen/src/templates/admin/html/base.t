to: assets/views/admin/base.html
skip_exists: true
message: "Admin base template was added successfully."
---
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>{% raw %}{% block title %}Admin Panel{% endblock title %}{% endraw %}</title>
  <script src="https://unpkg.com/htmx.org@2.0.0/dist/htmx.min.js"></script>
  <script src="https://cdn.tailwindcss.com?plugins=forms,typography,aspect-ratio,line-clamp"></script>
  {% raw %}{% block head %}{% endblock head %}{% endraw %}
</head>
<body class="min-h-screen bg-gray-100">
  <div class="flex">
    <!-- Sidebar -->
    <aside class="w-64 bg-gray-800 text-white min-h-screen">
      <div class="p-4">
        <h1 class="text-xl font-bold">Admin Panel</h1>
      </div>
      <nav class="mt-4">
        <a href="{{prefix}}/" class="block px-4 py-2 hover:bg-gray-700">Dashboard</a>
        {% raw %}{% block nav_items %}{% endblock nav_items %}{% endraw %}
      </nav>
    </aside>
    
    <!-- Main content -->
    <main class="flex-1 p-8">
      {% raw %}{% block content %}{% endblock content %}{% endraw %}
    </main>
  </div>
  
  <script>
    htmx.defineExtension('submitjson', {
      onEvent: function (name, evt) {
        if (name === "htmx:configRequest") {
          evt.detail.headers['Content-Type'] = "application/json"
        }
      },
      encodeParameters: function (xhr, parameters, elt) {
        const json = {};
        for (const [key, inputValue] of Object.entries(parameters)) {
          let origInputType = elt.querySelector(`[name=${key}]`).type;
          const customType = elt.querySelector(`[name=${key}]`).getAttribute("custom_type");
          let value = inputValue;
          if (customType == "array" && !Array.isArray(inputValue)) {
            value = [inputValue]
          }
          if (origInputType === 'number') {
            if (Array.isArray(value)) {
              json[key] = Object.values(value).map(str => parseFloat(str))
            } else {
              json[key] = parseFloat(value)
            }
          } else if (origInputType === 'checkbox') {
            const val = elt.querySelector(`[name=${key}]`).checked;
            json[key] = val
          } else if (customType === 'blob') {
            json[key] = value.split(",").map(num => parseInt(num, 10));
          } else {
            json[key] = value;
          }
        }
        return JSON.stringify(json);
      }
    })
    
    function confirmDelete(event, delete_url, redirect_to) {
      event.preventDefault();
      if (confirm("Are you sure you want to delete this item?")) {
        var xhr = new XMLHttpRequest();
        xhr.open("DELETE", delete_url, true);
        xhr.onreadystatechange = function () {
          if (xhr.readyState == 4 && xhr.status == 200) {
            window.location.href = redirect_to;
          }
        };
        xhr.send();
      }
    }
  </script>
</body>
</html>

