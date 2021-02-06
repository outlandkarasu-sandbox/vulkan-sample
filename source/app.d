import std.algorithm : map, each;
import std.string : toStringz;
import std.stdio : writeln, writefln;
import std.exception : enforce;
import std.conv : to;

import erupted :
    loadInstanceLevelFunctions,
    VK_MAKE_VERSION,
    VK_NULL_HANDLE,
    VkApplicationInfo,
    vkCreateInstance,
    vkDestroyInstance,
    vkEnumeratePhysicalDevices,
    vkGetPhysicalDeviceFeatures,
    vkGetPhysicalDeviceProperties,
    VkInstance,
    VkInstanceCreateInfo,
    VkPhysicalDevice,
    VkPhysicalDeviceFeatures,
    VkPhysicalDeviceProperties,
    VkResult;

import erupted.vulkan_lib_loader :
    loadGlobalLevelFunctions;

import karasutk.sdl :
    duringSDL,
    EventHandlers,
    runEventLoop,
    Window,
    WindowParameters;

private void enforceVK(VkResult res)
{
	enforce(res == VkResult.VK_SUCCESS, res.to!string);
}

void main()
{
    duringSDL(&vulkanMain);
}

void vulkanMain()
{
    WindowParameters params = {
        vulkan: true
    };
    auto window = Window.create(params);

    loadGlobalLevelFunctions();

    VkApplicationInfo appInfo = {
        pApplicationName: "Vulkan sample",
        apiVersion: VK_MAKE_VERSION(1, 0, 2),
    };

    auto extensions = window.vulkanInstanceExtensions;
    VkInstanceCreateInfo instInfo = {
        pApplicationInfo: &appInfo,
        enabledExtensionCount: cast(uint) extensions.length,
        ppEnabledExtensionNames: extensions.ptr,
    };

    VkInstance instance;
    enforceVK(vkCreateInstance(&instInfo, null, &instance));
    loadInstanceLevelFunctions(instance);

    scope(exit)
    {
        if (instance != VK_NULL_HANDLE)
        {
            vkDestroyInstance(instance, null);
        }
    }

    // enumerate devices.
    uint numPhysDevices;
    enforceVK(vkEnumeratePhysicalDevices(instance, &numPhysDevices, null));
    auto physDevices = new VkPhysicalDevice[](numPhysDevices);
    enforceVK(vkEnumeratePhysicalDevices(instance, &numPhysDevices, physDevices.ptr));

    enforce(physDevices.length > 0, "Device not found.");

    foreach (device; physDevices) {
        VkPhysicalDeviceProperties properties;
        device.vkGetPhysicalDeviceProperties(&properties);
        properties.writeln;

        VkPhysicalDeviceFeatures features;
        device.vkGetPhysicalDeviceFeatures(&features);
        features.writeln;
    }


    EventHandlers eventHandlers;
    window.runEventLoop(eventHandlers);
}

