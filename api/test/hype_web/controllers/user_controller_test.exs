defmodule HypeWeb.UserControllerTest do
  use HypeWeb.ConnCase

  alias Hype.{Accounts, Auth.Guardian}
  alias Hype.CommonTestData, as: TestData

  @user_params %{
    first_name: "test",
    last_name: "user",
    email: "test.user@example.com",
    password: "test_password"
  }

  @camel_case_user_params %{
    "firstName" => "test",
    "lastName" => "user",
    "email" => "test.user@example.com",
    "password" => "test_password"
  }

  @duplicate_email_user_params %{
    first_name: "test",
    last_name: "user",
    email: "test.user@example.com",
    password: "another_test_password"
  }

  describe "current_user" do
    setup :create_base_user

    test "returns proper error when authentication token not given", %{conn: conn} do
      conn =
        conn
        |> get("/api/users/")

      assert json_response(conn, 401)["ok"] == false
      assert json_response(conn, 401)["error"] == "unauthenticated"
    end

    test "returns the current authenticated user in the system", %{conn: conn, user: user} do
      conn =
        conn
        |> Guardian.Plug.sign_in(user)
        |> get("/api/users/")

      assert json_response(conn, 200)["ok"] == true
      assert json_response(conn, 200)["data"]["user"]["email"] == @user_params.email
      assert json_response(conn, 200)["data"]["user"]["firstName"] == @user_params.first_name
      assert json_response(conn, 200)["data"]["user"]["lastName"] == @user_params.last_name
    end
  end

  describe "create_user" do
    test "creates a user in the database", %{conn: conn} do
      conn =
        conn
        |> post("/api/users", @user_params)

      assert json_response(conn, 200)["ok"] == true
      assert json_response(conn, 200)["data"]["user"]["email"] == @user_params.email
      assert json_response(conn, 200)["data"]["user"]["firstName"] == @user_params.first_name
      assert json_response(conn, 200)["data"]["user"]["lastName"] == @user_params.last_name

      id = json_response(conn, 200)["data"]["user"]["id"]

      user_from_database = Accounts.get_user(id)

      assert user_from_database != nil
    end

    test "create a user with camel case parameters", %{conn: conn} do
      conn =
        conn
        |> post("/api/users", @camel_case_user_params)

      assert json_response(conn, 200)["ok"] == true
      assert json_response(conn, 200)["data"]["user"]["email"] == @user_params.email
      assert json_response(conn, 200)["data"]["user"]["firstName"] == @user_params.first_name
      assert json_response(conn, 200)["data"]["user"]["lastName"] == @user_params.last_name

      id = json_response(conn, 200)["data"]["user"]["id"]

      user_from_database = Accounts.get_user(id)

      assert user_from_database != nil
    end

    test "returns an error when user is sent with duplicate email", %{conn: conn} do
      TestData.create(:user)

      conn =
        conn
        |> post("/api/users", @duplicate_email_user_params)

      assert json_response(conn, 422)["ok"] == false
      assert json_response(conn, 422)["errors"]["email"] == ["has already been taken"]
    end
  end

  describe "delete user" do
    test "it deletes a user by user id" do
      user = TestData.create(:user)

      conn =
        conn
        |> Guardian.Plug.sign_in(user)
        |> delete("/api/users/")

      assert json_response(conn, 200)["ok"] == true
      assert json_response(conn, 200)["data"]["user"]["email"] == user.email
      assert json_response(conn, 200)["data"]["user"]["firstName"] == user.first_name
      assert json_response(conn, 200)["data"]["user"]["lastName"] == user.last_name

      user_from_database = Accounts.get_user(user.id)
    end
  end

  defp create_base_user(params) do
    user = TestData.create(:user)
    Map.put(params, :user, user)
  end
end
