module /*std.*/introspect;
//import std.typecons;

/**
Introspection information for a module named `moduleName`. Offers an entry
point for all accessible declarations within the module.
*/
struct Module(string moduleName)
{
    alias name = moduleName;

    /**
    Returns an array of all accessible top-level declarations in the module.
    */
    static immutable(string[]) allMembers()
    {
        mixin("static import " ~ name ~ ";");
        return mixin("[ __traits(allMembers, "~name~") ]");
    }

    /**
    Returns an array of all accessible top-level data declarations in the
    module for which static or thread-local storage gets allocated. These
    consist of global variables and global constants, but not `enum`s.
    */
    static immutable(Data[]) data()
    {
        static auto make()
        {
            Data[] result;
            enum all = allMembers;
            mixin("static import " ~ name ~ ";");
            static foreach (x; all)
            {{
                // Can the address be taken? Then it's data or function
                static if (is(typeof(mixin("&"~name~"."~x)) T))
                {
                    // Eliminate functions
                    static if (!mixin("is(typeof("~name~"."~x~") == function)"))
                    {
                        enum attributes = mixin("__traits(getAttributes,"
                            ~name~"."~x~")");
                        result ~= Data(x, T.stringof[0 .. $ - 1]);
                        static foreach (y; attributes)
                            result[$ - 1].attributes ~= y.stringof;
                    }
                }
            }}
            return result;
        }
        static immutable Data[] result = make();
        return result;
    }
}

struct Data
{
    string name;
    string type;
    string[] attributes;
}

unittest
{
    enum data = Module!"test1".data;
    static assert(data.length == 3);
    static assert(data[0] == Data("a1", "int"));
    static assert(data[1] == Data("a2", "immutable(string)", ["3"]));
    static assert(data[2] == Data("a3", "const(float[])", [`"test"`, "42"]));
}
