classdef MsgBundle < handle
    %MSGBUNDLE A container for input-output message pairs for learning a DistMapper.
    %
    %
    
    properties
    end
    
    methods (Abstract)

        % index = 1,..numInVars(). Return a DistArray for the input dimension 
        % specified by the index.
        distArray=getInputBundle(this, index);
        
        % return the number of incoming variables (connected variables to a factor)
        d=numInVars(this);

        % a DistArray representing array of output messages.
        distArray=getOutBundle(this);

        % return a bundle of incoming messages given the instanceIndex.
        inMsgs=getInputMsgs(instanceIndex);

        % Split this MsgBundle into training and testing bundles.
        % This MsgBundle should not change at all.
        % Since MsgBundle is a handle, trBundle, teBundle may refer internally 
        % to the data in this MsgBundle.
        % trProportion is in (0,1) for proportion of training samples.
        [trBundle, teBundle]=splitTrainTest(this, trProportion);

        % The number of instance pairs.
        n = count(this);

        % return a string description
        s=getDescription(this);
        
    end
    
end
