New project
1. Run <code>make init-new</code>
2. Setup db setup db connection in <code>./web/.env</code>
4. Run <code>make create-db</code>

Existing projects
1. Set your repo. In MakeFile line 	<code>@git clone <your-repo> web</code>"
2. Run <code>make init-existing</code>
3. Setup db setup db connection in <code>./web/.env</code>
4. Run <code>make create-db</code>

Laravel .env DB config example:<br>
<pre><code>DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=test
DB_USERNAME=root
DB_PASSWORD=root</code></pre>

<a href = "http://localhost:8080">http://localhost:8080</a>

Based: 'https://github.com/nanoninja/docker-nginx-php-mysql'